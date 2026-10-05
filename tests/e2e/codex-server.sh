#!/usr/bin/env bash
# Genuine ttyd/tmux/picker runtime; only the external Codex service is substituted.
set -euo pipefail
root=$(cd "$(dirname "$0")/../.." && pwd)
fixture=$(mktemp -d)
export CODEX_E2E_HOME="$fixture"
export TMUX_TMPDIR="$fixture"
export PATH="$fixture/bin:$PATH"
mkdir -p "$fixture/bin"
cleanup() { tmux kill-server 2>/dev/null || true; rm -rf "$fixture"; }
trap cleanup EXIT
cat > "$fixture/bin/codex-ha" <<'SCRIPT'
#!/usr/bin/env bash
printf 'CODEX_TEST_ARGS:%s\n' "$*"
exec bash --noprofile --norc
SCRIPT
cat > "$fixture/bin/codex" <<'SCRIPT'
#!/usr/bin/env bash
printf 'CODEX_TEST_ARGS:%s\n' "$*"
exec bash --noprofile --norc
SCRIPT
chmod +x "$fixture/bin/"*
export PS1='CODEX_E2E_SHELL> '
ttyd_bin=${TTYD_BIN:-ttyd}
if ! command -v "$ttyd_bin" >/dev/null; then
    echo 'Install ttyd (1.7.7+) or set TTYD_BIN to its executable.' >&2
    exit 1
fi
"$ttyd_bin" -p "${CODEX_E2E_PORT:-17681}" -i 127.0.0.1 -W -t rendererType=dom bash "$root/codex_terminal/scripts/codex-session-picker.sh" &
server=$!
trap 'kill "$server" 2>/dev/null || true; cleanup' EXIT INT TERM
wait "$server"
