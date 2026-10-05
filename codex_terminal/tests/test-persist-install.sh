#!/usr/bin/env bash
# Real persistence/jq; package-manager downloads are replaced with call recording.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
export PERSIST_INSTALL_CONFIG_FILE="$tmp/packages.json"
export PERSIST_TEST_CALLS="$tmp/calls"
mkdir "$tmp/bin"
for cmd in apk pip3; do
    cat > "$tmp/bin/$cmd" <<'STUB'
#!/usr/bin/env bash
printf '%s %s\n' "${0##*/}" "$*" >> "$PERSIST_TEST_CALLS"
STUB
    chmod +x "$tmp/bin/$cmd"
done
export PATH="$tmp/bin:$PATH"
script="$root/scripts/persist-install.sh"
bash "$script" list > "$tmp/list"
jq -e '.apk_packages == [] and .pip_packages == []' "$PERSIST_INSTALL_CONFIG_FILE" >/dev/null
bash "$script" apk tree jq tree
bash "$script" pip requests
bash "$script" apk nano
jq -e '.apk_packages == ["jq","nano","tree"] and .pip_packages == ["requests"]' "$PERSIST_INSTALL_CONFIG_FILE" >/dev/null
grep -qx 'apk add --no-cache tree jq tree' "$tmp/calls"
grep -qx 'pip3 install --break-system-packages --no-cache-dir requests' "$tmp/calls"
bash "$script" list > "$tmp/list"
grep -qx -- '- nano' "$tmp/list"
grep -qx -- '- requests' "$tmp/list"
cp "$PERSIST_INSTALL_CONFIG_FILE" "$tmp/before"
if bash "$script" apk; then echo 'Empty package list accepted' >&2; exit 1; fi
cmp "$PERSIST_INSTALL_CONFIG_FILE" "$tmp/before"
if bash "$script" unknown; then echo 'Invalid command accepted' >&2; exit 1; fi
cmp "$PERSIST_INSTALL_CONFIG_FILE" "$tmp/before"
echo 'PASS package persistence, deduplication, listing and command dispatch'
