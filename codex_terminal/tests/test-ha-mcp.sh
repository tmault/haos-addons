#!/usr/bin/env bash
# Real setup script and jq; Supervisor responses and external CLI are test doubles.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
source "$root/scripts/setup-ha-mcp.sh"

bashio::config() {
    case "$1" in
        enable_ha_mcp) echo "${enabled:-true}" ;;
        prefer_ha_mcp_app) echo "${preferred:-true}" ;;
    esac
}
bashio::log.info() { printf '%s\n' "$*" >> "$tmp/log"; }
bashio::log.warning() { printf '%s\n' "$*" >> "$tmp/log"; }
supervisor_get() {
    case "$1" in
        addons) printf '%s\n' "$response_addons" ;;
        addons/test_ha_mcp/info) printf '%s\n' "$response_info" ;;
        *) return 1 ;;
    esac
}
codex() {
    printf '%s\n' "$*" >> "$tmp/calls"
    if [[ "$*" == *--url* && "${fail_http:-false}" == true ]]; then
        echo 'Cannot reach private_testsecret'
        return 1
    fi
}
uvx() { :; }
export SUPERVISOR_TOKEN=test-supervisor-token
response_addons='{"data":{"addons":[{"slug":"unrelated"},{"slug":"test_ha_mcp"}]}}'
response_info='{"data":{"state":"started","options":{"secret_path":"/private_testsecret"},"dns":["test-ha-mcp.local.hass.io"],"network":{"9583/tcp":19583}}}'
reset() { : > "$tmp/calls"; : > "$tmp/log"; }
assert_call() { grep -Fxq -- "$1" "$tmp/calls"; }

reset
configure_ha_mcp_server
assert_call 'mcp remove home-assistant'
# Internal DNS must use the container port even if HA remaps the host port.
assert_call 'mcp add home-assistant --url http://test-ha-mcp.local.hass.io:9583/private_testsecret'
echo 'PASS internal DNS ignores remapped host port'

reset
response_info=$(jq '.data.dns=[] | .data.network["9583/tcp"]=null' <<< "$response_info")
configure_ha_mcp_server
assert_call 'mcp add home-assistant --url http://test-ha-mcp.local.hass.io:9583/private_testsecret'
echo 'PASS DNS fallback and unpublished host port'

for field in state secret; do
    reset
    original_response_info=$response_info
    if [[ "$field" == state ]]; then
        response_info=$(jq '.data.state="stopped"' <<< "$response_info")
    else
        response_info=$(jq 'del(.data.options.secret_path)' <<< "$response_info")
    fi
    configure_ha_mcp_server
    assert_call 'mcp add home-assistant --env HOMEASSISTANT_URL=http://supervisor/core --env HOMEASSISTANT_TOKEN=test-supervisor-token -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1'
    ! grep -q -- '--url' "$tmp/calls"
    response_info=$original_response_info
    echo "PASS $field unavailable selects stdio"
done

reset
fail_http=true
configure_ha_mcp_server
assert_call 'mcp add home-assistant --env HOMEASSISTANT_URL=http://supervisor/core --env HOMEASSISTANT_TOKEN=test-supervisor-token -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1'
! grep -q 'private_testsecret' "$tmp/log"
grep -Fq 'private_***' "$tmp/log"
fail_http=false
echo 'PASS HTTP failure selects stdio and redacts secret'

reset
response_addons='{"data":{"addons":[]}}'
configure_ha_mcp_server
grep -q -- '-- uvx' "$tmp/calls"
echo 'PASS absent add-on selects stdio'

reset
preferred=false
configure_ha_mcp_server
grep -q -- '-- uvx' "$tmp/calls"
preferred=true
echo 'PASS explicit stdio preference'

reset
enabled=false
configure_ha_mcp_server
[[ ! -s "$tmp/calls" ]]
enabled=true
echo 'PASS disabled integration does not mutate MCP'

reset
unset SUPERVISOR_TOKEN
configure_ha_mcp_server
[[ ! -s "$tmp/calls" ]]
echo 'PASS missing Supervisor token skips setup'
