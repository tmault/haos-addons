#!/usr/bin/env bash
# Input closure must terminate the picker, rather than repeatedly launching tmux.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d)
export TMUX_TMPDIR="$fixture"
export TERM=xterm
trap 'rm -rf "$fixture"' EXIT

for input in '' '4\n' '9\n'; do
    if printf '%b' "$input" | timeout 3 bash "$root/scripts/codex-session-picker.sh" > /dev/null 2>&1; then
        printf 'PASS picker exits on EOF after %q\n' "$input"
    else
        echo "Picker failed or spun after input closed: $input" >&2
        exit 1
    fi
done

printf '7\n' | timeout 3 bash "$root/scripts/codex-session-picker.sh" > /dev/null 2>&1
echo 'PASS explicit exit'
