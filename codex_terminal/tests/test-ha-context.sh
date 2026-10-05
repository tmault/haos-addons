#!/usr/bin/env bash
# Real renderer and jq, with deterministic external Supervisor responses.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"
export HA_CONTEXT_TEST_FIXTURE="$tmp"
export SUPERVISOR_TOKEN=context-test-secret
cat > "$tmp/bin/curl" <<'STUB'
#!/usr/bin/env bash
endpoint=${!#}
endpoint=${endpoint#http://supervisor/}
file=${endpoint//\//_}
cat "$HA_CONTEXT_TEST_FIXTURE/$file"
STUB
chmod +x "$tmp/bin/curl"
export PATH="$tmp/bin:$PATH"
printf '{"data":{"version":"2026.10","machine":"qemux86-64"}}\n' > "$tmp/core_info"
printf '{"data":{"hostname":"ha","operating_system":"HAOS"}}\n' > "$tmp/host_info"
printf '{"location_name":"Home","time_zone":"Europe/Zurich"}\n' > "$tmp/core_api_config"
printf '[{"entity_id":"light.office"},{"entity_id":"sensor.temperature"},{"entity_id":"light.hall"}]\n' > "$tmp/core_api_states"
printf '{"data":{"addons":[{"name":"Codex","version":"0.1.4","state":"started"},{"name":"Uninstalled","installed":false}]}}\n' > "$tmp/addons"
: > "$tmp/core_api_error_log"
script="$root/scripts/ha-context.sh"
bash "$script" --output "$tmp/context.md"
grep -q 'Home Assistant: 2026.10' "$tmp/context.md"
grep -q 'Total: 3 entities' "$tmp/context.md"
grep -q '| light | 2 |' "$tmp/context.md"
grep -q 'Codex v0.1.4 (started)' "$tmp/context.md"
! grep -q 'Uninstalled\|light.office\|context-test-secret' "$tmp/context.md"
bash "$script" --full --output "$tmp/context.md"
grep -q 'light.office' "$tmp/context.md"
[[ $(stat -c '%a' "$tmp/context.md") == 644 ]]

# Missing optional API fields must still produce a complete refreshed document.
printf '{}\n' > "$tmp/core_api_config"
bash "$script" --output "$tmp/context.md"
grep -q '## API Access' "$tmp/context.md"
printf 'invalid-json\n' > "$tmp/core_info"
printf 'invalid-json\n' > "$tmp/core_api_states"
printf 'invalid-json\n' > "$tmp/addons"
bash "$script" --output "$tmp/context.md"
grep -q 'Unable to retrieve system information' "$tmp/context.md"
grep -q 'Unable to retrieve entity states' "$tmp/context.md"
grep -q 'Unable to retrieve app information' "$tmp/context.md"
printf '{"error":"unauthorized"}\n' > "$tmp/core_api_states"
printf '{"data":{"addons":"unavailable"}}\n' > "$tmp/addons"
bash "$script" --output "$tmp/context.md"
grep -q 'Unable to retrieve entity states' "$tmp/context.md"
grep -q 'Unable to retrieve app information' "$tmp/context.md"
rm "$tmp/core_info" "$tmp/host_info" "$tmp/core_api_config" "$tmp/core_api_states" "$tmp/addons"
bash "$script" --output "$tmp/context.md"
grep -q '## API Access' "$tmp/context.md"
cp "$tmp/context.md" "$tmp/before"
if env -u SUPERVISOR_TOKEN bash "$script" --output "$tmp/context.md"; then exit 1; fi
cmp "$tmp/context.md" "$tmp/before"
echo 'PASS context summary/full rendering, partial APIs and safe prerequisite failure'
