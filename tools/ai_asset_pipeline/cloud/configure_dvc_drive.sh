#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CRIA_DVC_REMOTE_URL:-}" ]]; then
  echo "CRIA_DVC_REMOTE_URL must be set to a private gdrive:// folder URL." >&2
  exit 2
fi
if [[ ! "${CRIA_DVC_REMOTE_URL}" =~ ^gdrive://[A-Za-z0-9_-]+(/.*)?$ ]]; then
  echo "CRIA_DVC_REMOTE_URL is not a valid private gdrive:// folder URL." >&2
  exit 2
fi
if ! command -v dvc >/dev/null 2>&1; then
  echo "DVC with Google Drive support is not installed." >&2
  exit 2
fi

dvc remote add --local --force cria-private "${CRIA_DVC_REMOTE_URL}"
dvc remote default --local cria-private
dvc remote modify --local cria-private gdrive_trash_only true
dvc remote modify --local cria-private profile cria-do-tatame
echo "Private DVC remote configured locally. No provider ID was written to tracked config."
