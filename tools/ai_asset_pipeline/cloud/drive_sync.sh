#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../../.." && pwd)"
RCLONE_REMOTE="${CRIA_RCLONE_REMOTE:-gdrive}"
DRIVE_ROOT_PATH="${CRIA_DRIVE_ROOT_PATH:-CriaDoTatame}"
APPROVED_LOCAL="${CRIA_APPROVED_LOCAL:-${REPO_ROOT}/assets/cloud_approved}"
MODELS_LOCAL="${CRIA_MODELS_LOCAL:-${REPO_ROOT}/models}"

usage() {
  echo "Usage: $0 [--dry-run] <check|pull-approved|mirror-approved|push-candidates|pull-models> [path]"
}

die() {
  echo "drive_sync: $*" >&2
  exit 2
}

DRY_RUN=()
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=(--dry-run)
  shift
fi

COMMAND="${1:-}"
shift || true

command -v rclone >/dev/null 2>&1 || die "rclone is not installed"
rclone listremotes | grep -Fxq "${RCLONE_REMOTE}:" || die "rclone remote '${RCLONE_REMOTE}' is not configured"

COMMON_FLAGS=(
  --checksum
  --checkers 8
  --transfers 4
  --create-empty-src-dirs
  --drive-skip-gdocs
  --progress
)

case "${COMMAND}" in
  check)
    rclone lsf "${RCLONE_REMOTE}:${DRIVE_ROOT_PATH}" --dirs-only --max-depth 2
    ;;
  pull-approved)
    mkdir -p -- "${APPROVED_LOCAL}"
    rclone copy \
      "${RCLONE_REMOTE}:${DRIVE_ROOT_PATH}/assets/aprovados" \
      "${APPROVED_LOCAL}" \
      "${COMMON_FLAGS[@]}" \
      "${DRY_RUN[@]}"
    ;;
  mirror-approved)
    [[ "${CRIA_ALLOW_RCLONE_DELETE:-}" == "YES" ]] || die \
      "mirror-approved can delete local files; set CRIA_ALLOW_RCLONE_DELETE=YES after reviewing --dry-run"
    mkdir -p -- "${APPROVED_LOCAL}"
    rclone sync \
      "${RCLONE_REMOTE}:${DRIVE_ROOT_PATH}/assets/aprovados" \
      "${APPROVED_LOCAL}" \
      "${COMMON_FLAGS[@]}" \
      "${DRY_RUN[@]}"
    ;;
  push-candidates)
    SOURCE="${1:-}"
    [[ -n "${SOURCE}" ]] || die "push-candidates requires a file or directory path"
    [[ -e "${SOURCE}" ]] || die "candidate source does not exist: ${SOURCE}"
    rclone copy \
      "${SOURCE}" \
      "${RCLONE_REMOTE}:${DRIVE_ROOT_PATH}/assets/candidatos" \
      "${COMMON_FLAGS[@]}" \
      "${DRY_RUN[@]}"
    ;;
  pull-models)
    mkdir -p -- "${MODELS_LOCAL}"
    rclone copy \
      "${RCLONE_REMOTE}:${DRIVE_ROOT_PATH}/models" \
      "${MODELS_LOCAL}" \
      "${COMMON_FLAGS[@]}" \
      "${DRY_RUN[@]}"
    ;;
  -h|--help|help)
    usage
    ;;
  "")
    usage
    exit 2
    ;;
  *)
    die "unknown command: ${COMMAND}"
    ;;
esac
