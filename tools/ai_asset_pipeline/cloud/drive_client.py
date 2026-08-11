#!/usr/bin/env python3
"""Google Drive transport for the Cria do Tatame audiovisual pipeline.

The client keeps OAuth material and provider file IDs outside the repository.
Only portable provenance (logical path, size and SHA-256) is written to the
versioned manifest. Generated files always enter ``assets/candidatos``; this
tool deliberately has no command that promotes them to shipping assets.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import mimetypes
import os
import sys
import tempfile
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

ROOT = Path(__file__).resolve().parents[3]
DEFAULT_LAYOUT = ROOT / "data" / "ai" / "cloud_drive_layout_v01.json"
DEFAULT_PUBLIC_MANIFEST = ROOT / "data" / "ai" / "cloud_asset_manifest_v01.json"
FOLDER_MIME = "application/vnd.google-apps.folder"
DRIVE_SCOPE = "https://www.googleapis.com/auth/drive"


class DrivePipelineError(RuntimeError):
    """Raised when cloud state is ambiguous or violates the pipeline contract."""


def sha256_file(path: Path) -> str:
    """Return the SHA-256 digest of *path* without loading it into memory."""

    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def load_json(path: Path) -> dict[str, Any]:
    """Load a UTF-8 JSON object and reject non-object top-level values."""

    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise DrivePipelineError(f"JSON root must be an object: {path}")
    return value


def atomic_write_json(path: Path, value: dict[str, Any]) -> None:
    """Atomically replace *path* with a stable UTF-8 JSON representation."""

    path.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    fd, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as handle:
            handle.write(payload)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def default_config_dir() -> Path:
    """Return the user-local configuration directory used for private state."""

    configured = os.environ.get("XDG_CONFIG_HOME")
    base = Path(configured).expanduser() if configured else Path.home() / ".config"
    return base / "cria-do-tatame" / "drive"


def build_drive_service(client_secrets: Path, token_path: Path) -> Any:
    """Authenticate an installed application and return a Drive API v3 service."""

    try:
        from google.auth.transport.requests import Request
        from google.oauth2.credentials import Credentials
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError as exc:
        raise DrivePipelineError(
            "Google Drive dependencies are missing; install requirements-drive.txt"
        ) from exc

    credentials = None
    token_changed = False
    if token_path.exists():
        credentials = Credentials.from_authorized_user_file(str(token_path), [DRIVE_SCOPE])
    if credentials and credentials.expired and credentials.refresh_token:
        credentials.refresh(Request())
        token_changed = True
    if not credentials or not credentials.valid:
        if not client_secrets.is_file():
            raise DrivePipelineError(
                f"OAuth client file not found: {client_secrets}. Keep it outside the repository."
            )
        flow = InstalledAppFlow.from_client_secrets_file(str(client_secrets), [DRIVE_SCOPE])
        credentials = flow.run_local_server(port=0, open_browser=True)
        token_changed = True
    if token_changed:
        token_path.parent.mkdir(parents=True, exist_ok=True)
        atomic_write_json(token_path, json.loads(credentials.to_json()))
        try:
            token_path.chmod(0o600)
        except OSError:
            pass
    return build("drive", "v3", credentials=credentials, cache_discovery=False)


def _escape_drive_query(value: str) -> str:
    return value.replace("\\", "\\\\").replace("'", "\\'")


def _validate_logical_path(value: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or not path.parts or any(part in {"", ".", ".."} for part in path.parts):
        raise DrivePipelineError(f"Unsafe logical Drive path: {value!r}")
    return path


class DriveClient:
    """Idempotent folder and file operations for the private project tree."""

    def __init__(
        self,
        service: Any,
        layout: dict[str, Any],
        private_state_path: Path,
        root_id: str | None = None,
    ) -> None:
        self.service = service
        self.layout = layout
        self.private_state_path = private_state_path
        self.private_state = (
            load_json(private_state_path)
            if private_state_path.exists()
            else {"schema_version": 1, "folders": {}, "objects": {}}
        )
        self.root_id = root_id or os.environ.get("CRIA_DRIVE_ROOT_ID") or self.private_state.get("root_id")

    def _list_named(self, name: str, parent_id: str, mime_type: str | None = None) -> list[dict[str, Any]]:
        clauses = [
            f"'{_escape_drive_query(parent_id)}' in parents",
            f"name = '{_escape_drive_query(name)}'",
            "trashed = false",
        ]
        if mime_type:
            clauses.append(f"mimeType = '{_escape_drive_query(mime_type)}'")
        matches: list[dict[str, Any]] = []
        page_token = None
        while True:
            response = (
                self.service.files()
                .list(
                    q=" and ".join(clauses),
                    spaces="drive",
                    fields="nextPageToken,files(id,name,mimeType,size,md5Checksum,parents)",
                    pageSize=100,
                    pageToken=page_token,
                )
                .execute()
            )
            matches.extend(response.get("files", []))
            page_token = response.get("nextPageToken")
            if not page_token:
                return matches

    @staticmethod
    def _unique(matches: list[dict[str, Any]], description: str) -> dict[str, Any] | None:
        if len(matches) > 1:
            ids = ", ".join(str(item.get("id")) for item in matches)
            raise DrivePipelineError(f"Ambiguous {description}; duplicate IDs: {ids}")
        return matches[0] if matches else None

    def _create_folder(self, name: str, parent_id: str) -> dict[str, Any]:
        return (
            self.service.files()
            .create(
                body={"name": name, "mimeType": FOLDER_MIME, "parents": [parent_id]},
                fields="id,name,mimeType,parents",
            )
            .execute()
        )

    def resolve_root(self, create: bool = False) -> str:
        """Resolve the root by explicit ID/state, or by an exact unique name."""

        if self.root_id:
            metadata = self.service.files().get(fileId=self.root_id, fields="id,name,mimeType,trashed").execute()
            if metadata.get("trashed") or metadata.get("mimeType") != FOLDER_MIME:
                raise DrivePipelineError("CRIA_DRIVE_ROOT_ID does not reference an active folder")
            expected = self.layout["root_folder_name"]
            if metadata.get("name") != expected:
                raise DrivePipelineError(
                    f"Drive root is named {metadata.get('name')!r}; expected {expected!r}"
                )
            return str(metadata["id"])

        name = str(self.layout["root_folder_name"])
        match = self._unique(self._list_named(name, "root", FOLDER_MIME), f"root folder {name!r}")
        if not match:
            if not create:
                raise DrivePipelineError(
                    f"Drive root {name!r} was not found. Run init-tree or set CRIA_DRIVE_ROOT_ID."
                )
            match = self._create_folder(name, "root")
        self.root_id = str(match["id"])
        return self.root_id

    def ensure_folder(self, logical_path: str, create: bool) -> str:
        """Resolve or create a nested project folder without flattening its hierarchy."""

        path = _validate_logical_path(logical_path)
        parent_id = self.resolve_root(create=create)
        current_parts: list[str] = []
        for part in path.parts:
            current_parts.append(part)
            key = "/".join(current_parts)
            cached = self.private_state.get("folders", {}).get(key)
            if cached:
                try:
                    metadata = self.service.files().get(fileId=cached, fields="id,name,mimeType,trashed,parents").execute()
                    if (
                        not metadata.get("trashed")
                        and metadata.get("mimeType") == FOLDER_MIME
                        and metadata.get("name") == part
                        and parent_id in metadata.get("parents", [])
                    ):
                        parent_id = str(metadata["id"])
                        continue
                except Exception:
                    pass
            match = self._unique(self._list_named(part, parent_id, FOLDER_MIME), f"folder {key!r}")
            if not match:
                if not create:
                    raise DrivePipelineError(f"Required Drive folder is missing: {key}")
                match = self._create_folder(part, parent_id)
            parent_id = str(match["id"])
            self.private_state.setdefault("folders", {})[key] = parent_id
        return parent_id

    def save_private_state(self) -> None:
        """Persist provider IDs outside the repository with restrictive permissions."""

        self.private_state["root_id"] = self.resolve_root(create=False)
        atomic_write_json(self.private_state_path, self.private_state)
        try:
            self.private_state_path.chmod(0o600)
        except OSError:
            pass

    def ensure_tree(self) -> dict[str, str]:
        """Create every folder from the executable Drive layout contract."""

        resolved: dict[str, str] = {}
        self.resolve_root(create=True)
        for logical_path in self.layout["folders"]:
            resolved[logical_path] = self.ensure_folder(logical_path, create=True)
        self.save_private_state()
        return resolved

    def verify_tree(self) -> dict[str, str]:
        """Resolve every required folder without mutating Drive."""

        resolved = {
            logical_path: self.ensure_folder(logical_path, create=False)
            for logical_path in self.layout["folders"]
        }
        self.save_private_state()
        return resolved

    def upload_file(self, source: Path, destination: str, if_exists: str) -> dict[str, Any]:
        """Upload one file to a logical folder using a resumable transfer."""

        if not source.is_file():
            raise DrivePipelineError(f"Upload source is not a file: {source}")
        parent_id = self.ensure_folder(destination, create=False)
        existing = self._unique(
            self._list_named(source.name, parent_id),
            f"file {destination}/{source.name}",
        )
        try:
            from googleapiclient.http import MediaFileUpload
        except ImportError as exc:
            raise DrivePipelineError("google-api-python-client is not installed") from exc

        mime_type = mimetypes.guess_type(source.name)[0] or "application/octet-stream"
        media = MediaFileUpload(str(source), mimetype=mime_type, resumable=True, chunksize=8 * 1024 * 1024)
        fields = "id,name,mimeType,size,md5Checksum,parents,modifiedTime"
        if existing:
            if if_exists == "fail":
                raise DrivePipelineError(
                    f"Drive file already exists: {destination}/{source.name}. Use --if-exists replace or reuse."
                )
            if if_exists == "reuse":
                return existing
            result = (
                self.service.files()
                .update(fileId=existing["id"], media_body=media, fields=fields)
                .execute()
            )
        else:
            result = (
                self.service.files()
                .create(
                    body={"name": source.name, "parents": [parent_id]},
                    media_body=media,
                    fields=fields,
                )
                .execute()
            )
        return dict(result)

    def download_file(self, file_id: str, target: Path, expected_sha256: str | None) -> str:
        """Download one Drive object atomically and optionally verify SHA-256."""

        try:
            from googleapiclient.http import MediaIoBaseDownload
        except ImportError as exc:
            raise DrivePipelineError("google-api-python-client is not installed") from exc

        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_suffix(target.suffix + ".partial")
        request = self.service.files().get_media(fileId=file_id)
        with temporary.open("wb") as handle:
            downloader = MediaIoBaseDownload(handle, request, chunksize=8 * 1024 * 1024)
            done = False
            while not done:
                _, done = downloader.next_chunk()
        actual = sha256_file(temporary)
        if expected_sha256 and actual.lower() != expected_sha256.lower():
            temporary.unlink(missing_ok=True)
            raise DrivePipelineError(
                f"SHA-256 mismatch for {file_id}: expected {expected_sha256}, got {actual}"
            )
        os.replace(temporary, target)
        return actual

    def register_upload(
        self,
        source: Path,
        destination: str,
        drive_file: dict[str, Any],
        public_manifest_path: Path,
    ) -> str:
        """Record private provider ID separately from public, portable provenance."""

        try:
            from filelock import FileLock
        except ImportError as exc:
            raise DrivePipelineError("filelock is not installed") from exc

        digest = sha256_file(source)
        object_key = f"sha256:{digest}"
        self.private_state.setdefault("objects", {})[object_key] = {
            "drive_file_id": drive_file["id"],
            "logical_path": f"{destination}/{source.name}",
        }
        self.save_private_state()

        with FileLock(str(public_manifest_path) + ".lock", timeout=30):
            manifest = load_json(public_manifest_path)
            manifest.setdefault("assets", {})[object_key] = {
                "bytes": source.stat().st_size,
                "filename": source.name,
                "logical_path": f"{destination}/{source.name}",
                "provider_locator": "private_state",
                "sha256": digest,
                "status": "candidate",
            }
            atomic_write_json(public_manifest_path, manifest)
        return object_key


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line interface."""

    config_dir = default_config_dir()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--layout", type=Path, default=DEFAULT_LAYOUT)
    parser.add_argument("--public-manifest", type=Path, default=DEFAULT_PUBLIC_MANIFEST)
    parser.add_argument(
        "--client-secrets",
        type=Path,
        default=Path(os.environ.get("CRIA_DRIVE_CLIENT_SECRET", config_dir / "client_secret.json")),
    )
    parser.add_argument(
        "--token",
        type=Path,
        default=Path(os.environ.get("CRIA_DRIVE_TOKEN", config_dir / "token.json")),
    )
    parser.add_argument(
        "--private-state",
        type=Path,
        default=Path(os.environ.get("CRIA_DRIVE_STATE", config_dir / "state.json")),
    )
    parser.add_argument("--root-id", default=None)
    subparsers = parser.add_subparsers(dest="command", required=True)
    subparsers.add_parser("init-tree", help="Create missing folders idempotently")
    subparsers.add_parser("verify-tree", help="Verify the complete hierarchy without creating folders")

    upload = subparsers.add_parser("upload-batch", help="Upload one candidate ZIP and register its SHA-256")
    upload.add_argument("source", type=Path)
    upload.add_argument("--destination", default="assets/candidatos")
    upload.add_argument("--if-exists", choices=["fail", "replace", "reuse"], default="fail")

    download = subparsers.add_parser("download", help="Download and integrity-check one private object")
    download.add_argument("file_id")
    download.add_argument("target", type=Path)
    download.add_argument("--sha256", default=None)
    return parser


def _print_result(value: Any) -> None:
    print(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True))


def run(argv: Iterable[str] | None = None) -> int:
    """Execute the Drive CLI and return a process exit code."""

    args = build_parser().parse_args(list(argv) if argv is not None else None)
    layout = load_json(args.layout)
    service = build_drive_service(args.client_secrets.expanduser(), args.token.expanduser())
    client = DriveClient(
        service=service,
        layout=layout,
        private_state_path=args.private_state.expanduser(),
        root_id=args.root_id,
    )

    if args.command == "init-tree":
        _print_result({"ok": True, "folders": client.ensure_tree()})
    elif args.command == "verify-tree":
        _print_result({"ok": True, "folders": client.verify_tree()})
    elif args.command == "upload-batch":
        if args.source.suffix.lower() != ".zip":
            raise DrivePipelineError("upload-batch accepts only ZIP bundles")
        destination = str(_validate_logical_path(args.destination))
        allowed = set(layout["upload_destinations"])
        if destination not in allowed:
            raise DrivePipelineError(
                f"Upload destination {destination!r} is not allowlisted: {sorted(allowed)}"
            )
        drive_file = client.upload_file(args.source, destination, args.if_exists)
        object_key = client.register_upload(
            args.source,
            destination,
            drive_file,
            args.public_manifest,
        )
        _print_result(
            {
                "ok": True,
                "object_key": object_key,
                "logical_path": f"{destination}/{args.source.name}",
                "sha256": sha256_file(args.source),
            }
        )
    elif args.command == "download":
        digest = client.download_file(args.file_id, args.target, args.sha256)
        _print_result({"ok": True, "target": str(args.target), "sha256": digest})
    return 0


def main() -> int:
    """CLI entrypoint with concise, non-secret error reporting."""

    try:
        return run()
    except (DrivePipelineError, OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"drive pipeline error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
