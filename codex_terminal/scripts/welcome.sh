#!/bin/bash

GREEN='\033[0;32m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

MOTD_VERSION_FILE="/data/.codex-terminal-motd-version"
APP_VERSION_FILE="/opt/scripts/app-version"

get_current_version() {
    if [ -f "$APP_VERSION_FILE" ]; then
        cat "$APP_VERSION_FILE"
    else
        echo "unknown"
    fi
}

get_last_seen_version() {
    cat "$MOTD_VERSION_FILE" 2>/dev/null || echo "none"
}

save_version() {
    echo "$1" > "$MOTD_VERSION_FILE" 2>/dev/null || true
}

main() {
    local current_version last_seen
    current_version=$(get_current_version)
    last_seen=$(get_last_seen_version)

    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${WHITE}Codex Terminal${NC} ${DIM}v${current_version}${NC}"
    echo -e "  ${DIM}Home Assistant App - Powered by OpenAI Codex CLI${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""

    if [ "$current_version" != "$last_seen" ] && [ "$current_version" != "unknown" ]; then
        echo "  Notes:"
        echo "  - Codex starts in /config with workspace-write sandboxing."
        echo "  - The home-assistant MCP server is configured when ha_mcp is enabled."
        echo "  - Run ha-context to refresh the generated Home Assistant context."
        echo ""
        save_version "$current_version"
    fi

    printf "  Press Enter to continue..."
    read -r
}

main "$@"
