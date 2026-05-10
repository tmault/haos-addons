#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"

cat > "$TMP_DIR/bin/codex-update" <<'SCRIPT'
#!/bin/bash
printf '%s\n' "$*" >> "$CODEX_UPDATE_CALLS_FILE"
SCRIPT

chmod 755 "$TMP_DIR/bin/codex-update"

export PATH="$TMP_DIR/bin:$PATH"
export CODEX_UPDATE_CALLS_FILE="$TMP_DIR/calls"
export CODEX_UPDATE_LAST_RUN_FILE="$TMP_DIR/last-run"
export CODEX_UPDATE_TARGET="latest"

run_scheduler_once() {
    CODEX_UPDATE_NOW_DATE="$1" \
    CODEX_UPDATE_NOW_TIME="$2" \
    CODEX_UPDATE_NOW_DAY="$3" \
    CODEX_UPDATE_SCHEDULE_TIME="$4" \
    CODEX_UPDATE_SCHEDULE_DAYS="$5" \
    "$ROOT_DIR/scripts/codex-update-scheduler.sh" --run-once
}

run_scheduler_once 2026-05-10 03:30 sun 03:30 daily

grep -qx "latest" "$CODEX_UPDATE_CALLS_FILE"
grep -qx "2026-05-10" "$CODEX_UPDATE_LAST_RUN_FILE"

run_scheduler_once 2026-05-10 03:30 sun 03:30 daily
test "$(wc -l < "$CODEX_UPDATE_CALLS_FILE" | tr -d ' ')" = "1"

run_scheduler_once 2026-05-11 03:30 mon 03:30 "tue,thu"
test "$(wc -l < "$CODEX_UPDATE_CALLS_FILE" | tr -d ' ')" = "1"

run_scheduler_once 2026-05-12 03:30 tue 03:30 "tue,thu"
test "$(wc -l < "$CODEX_UPDATE_CALLS_FILE" | tr -d ' ')" = "2"

echo "codex-update-scheduler test passed"
