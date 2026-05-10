#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

mkdir -p "$TMP_DIR/bin"

cat > "$TMP_DIR/bin/codex" <<'SCRIPT'
#!/bin/bash
echo "codex-cli 0.130.0"
SCRIPT

cat > "$TMP_DIR/bin/npm" <<'SCRIPT'
#!/bin/bash
printf '%s\n' "$*" >> "$NPM_CALLS_FILE"
if [ "$1" = "view" ]; then
    echo "0.131.0"
fi
SCRIPT

chmod 755 "$TMP_DIR/bin/codex" "$TMP_DIR/bin/npm"

export PATH="$TMP_DIR/bin:$PATH"
export NPM_CALLS_FILE="$TMP_DIR/npm-calls"
export CODEX_CLI_VERSION_FILE="$TMP_DIR/codex-cli-version"

"$ROOT_DIR/scripts/codex-update.sh" latest > "$TMP_DIR/output"

grep -q "view @openai/codex@latest version" "$NPM_CALLS_FILE"
grep -q "install -g @openai/codex@0.131.0" "$NPM_CALLS_FILE"
grep -q "0.131.0" "$CODEX_CLI_VERSION_FILE"
grep -q "Restart Codex or open a new terminal session" "$TMP_DIR/output"

echo "codex-update test passed"
