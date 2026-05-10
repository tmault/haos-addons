#!/usr/bin/with-contenv bashio

set -e

supervisor_get() {
    local endpoint="$1"
    curl -sS -m 10 \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        "http://supervisor/${endpoint}" 2>/dev/null
}

find_ha_mcp_slug() {
    local addons
    addons=$(supervisor_get "addons" || true)
    echo "$addons" | jq -r '.data.addons[]? | select(.slug | endswith("_ha_mcp")) | .slug' 2>/dev/null | head -n 1
}

configure_ha_mcp_app_endpoint() {
    local prefer_ha_mcp_app slug info state secret_path dns port endpoint
    prefer_ha_mcp_app=$(bashio::config 'prefer_ha_mcp_app' 'true')

    if [ "$prefer_ha_mcp_app" != "true" ]; then
        return 1
    fi

    slug=$(find_ha_mcp_slug)
    if [ -z "$slug" ]; then
        bashio::log.info "Home Assistant MCP Server app is not installed; trying stdio fallback"
        return 1
    fi

    info=$(supervisor_get "addons/${slug}/info" || true)
    state=$(echo "$info" | jq -r '.data.state // empty' 2>/dev/null)
    secret_path=$(echo "$info" | jq -r '.data.options.secret_path // empty' 2>/dev/null)
    dns=$(echo "$info" | jq -r '.data.dns[0] // empty' 2>/dev/null)
    port=$(echo "$info" | jq -r '.data.network["9583/tcp"] // 9583' 2>/dev/null)

    if [ "$state" != "started" ]; then
        bashio::log.warning "Home Assistant MCP Server app is installed but not started; trying stdio fallback"
        return 1
    fi

    if [ -z "$secret_path" ] || [ "$secret_path" = "null" ]; then
        bashio::log.warning "Home Assistant MCP Server secret path is unavailable; trying stdio fallback"
        return 1
    fi

    if [ -z "$dns" ] || [ "$dns" = "null" ]; then
        dns="${slug//_/-}.local.hass.io"
    fi

    if [ -z "$port" ] || [ "$port" = "null" ]; then
        port="9583"
    fi

    endpoint="http://${dns}:${port}${secret_path}"

    bashio::log.info "Configuring Codex MCP server from Home Assistant MCP Server app endpoint..."
    if codex mcp add home-assistant --url "$endpoint" >/tmp/codex-mcp-add.log 2>&1; then
        bashio::log.info "ha_mcp app endpoint configured successfully"
        return 0
    fi

    bashio::log.warning "Failed to configure ha_mcp app endpoint; trying stdio fallback"
    sed 's/private_[A-Za-z0-9_-]*/private_***/g' /tmp/codex-mcp-add.log | while IFS= read -r line; do
        bashio::log.warning "$line"
    done
    return 1
}

configure_stdio_fallback() {
    if ! command -v uvx >/dev/null 2>&1; then
        bashio::log.warning "uvx not found; cannot configure ha_mcp stdio fallback"
        return 1
    fi

    bashio::log.info "Configuring Codex MCP server with uvx ha-mcp stdio fallback..."
    if codex mcp add home-assistant \
        --env "HOMEASSISTANT_URL=http://supervisor/core" \
        --env "HOMEASSISTANT_TOKEN=${SUPERVISOR_TOKEN}" \
        -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1 >/tmp/codex-mcp-add.log 2>&1; then
        bashio::log.info "ha_mcp stdio fallback configured successfully"
        return 0
    fi

    bashio::log.warning "Failed to configure ha_mcp stdio fallback"
    while IFS= read -r line; do
        bashio::log.warning "$line"
    done < /tmp/codex-mcp-add.log
    return 1
}

configure_ha_mcp_server() {
    local enable_ha_mcp
    enable_ha_mcp=$(bashio::config 'enable_ha_mcp' 'true')

    if [ "$enable_ha_mcp" != "true" ]; then
        bashio::log.info "ha_mcp integration is disabled in configuration"
        return 0
    fi

    if [ -z "${SUPERVISOR_TOKEN:-}" ]; then
        bashio::log.warning "SUPERVISOR_TOKEN not available; ha_mcp setup skipped"
        return 0
    fi

    if ! command -v codex >/dev/null 2>&1; then
        bashio::log.warning "codex command not found; ha_mcp setup skipped"
        return 0
    fi

    codex mcp remove home-assistant >/dev/null 2>&1 || true

    if configure_ha_mcp_app_endpoint; then
        bashio::log.info "Codex now has access to Home Assistant through ha_mcp"
        return 0
    fi

    if configure_stdio_fallback; then
        bashio::log.info "Codex now has access to Home Assistant through ha_mcp"
        return 0
    fi

    bashio::log.warning "Codex will start without Home Assistant MCP tools"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_ha_mcp_server
fi
