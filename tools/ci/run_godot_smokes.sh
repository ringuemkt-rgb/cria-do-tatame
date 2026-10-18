#!/usr/bin/env bash
set -euo pipefail

cria_engine="${1:-godot}"
cria_log_dir="${2:-reports/full_game_audit}"
mkdir -p "$cria_log_dir"
cria_log_dir="$(cd "$cria_log_dir" && pwd)"
cria_count=0
for cria_test in tests/*_smoke.gd; do
  cria_name="$(basename "$cria_test" .gd)"
  cria_data="$(mktemp -d -t cria-smoke-data-XXXXXXXX)"
  env XDG_DATA_HOME="$cria_data" timeout 120 "$cria_engine" --headless --path . \
    --script "res://$cria_test" 2>&1 | tee "$cria_log_dir/$cria_name.log"
  if grep -Eq 'SCRIPT ERROR|Parse Error|Invalid call|Failed loading resource|Cannot get class|^ERROR:' "$cria_log_dir/$cria_name.log"; then
    echo "Hidden Godot error in $cria_test"
    exit 1
  fi
  cria_count=$((cria_count + 1))
done
test "$cria_count" -gt 0
echo "Godot smoke suite: $cria_count scripts passed"
