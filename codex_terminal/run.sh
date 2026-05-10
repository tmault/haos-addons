#!/usr/bin/with-contenv bashio

set -e
set -o pipefail

init_environment() {
    local data_home="/data/home"
    local codex_home="/data/.codex"
    local config_dir="/data/.config"
    local cache_dir="/data/.cache"
    local state_dir="/data/.local/state"
    local data_dir="/data/.local/share"

    bashio::log.info "Initializing Codex environment in /data..."

    mkdir -p "$data_home" "$codex_home" "$config_dir" "$cache_dir" "$state_dir" "$data_dir"
    chmod 755 "$data_home" "$codex_home" "$config_dir" "$cache_dir" "$state_dir" "$data_dir"

    export HOME="$data_home"
    export CODEX_HOME="$codex_home"
    export XDG_CONFIG_HOME="$config_dir"
    export XDG_CACHE_HOME="$cache_dir"
    export XDG_STATE_HOME="$state_dir"
    export XDG_DATA_HOME="$data_dir"

    migrate_legacy_codex_files "$codex_home"

    if [ ! -e "$data_home/.codex" ]; then
        ln -s "$codex_home" "$data_home/.codex"
    fi

    if [ -f "/opt/scripts/tmux.conf" ]; then
        cp /opt/scripts/tmux.conf "$data_home/.tmux.conf"
        chmod 644 "$data_home/.tmux.conf"
        bashio::log.info "tmux configuration installed to $data_home/.tmux.conf"
    fi

    ensure_codex_config

    bashio::log.info "Environment initialized:"
    bashio::log.info "  - Home: $HOME"
    bashio::log.info "  - Codex home: $CODEX_HOME"
    bashio::log.info "  - Config: $XDG_CONFIG_HOME"
    bashio::log.info "  - Cache: $XDG_CACHE_HOME"
}

migrate_legacy_codex_files() {
    local target_dir="$1"
    local migrated=false
    local legacy_locations=(
        "/root/.codex"
        "/config/codex-config"
        "/tmp/codex-config"
    )

    bashio::log.info "Checking for existing Codex files to migrate..."

    for legacy_path in "${legacy_locations[@]}"; do
        if [ -d "$legacy_path" ] && [ "$(ls -A "$legacy_path" 2>/dev/null)" ]; then
            bashio::log.info "Migrating Codex files from: $legacy_path"
            if cp -a "$legacy_path"/. "$target_dir/" 2>/dev/null; then
                find "$target_dir" -type f -name "auth.json" -exec chmod 600 {} \;
                migrated=true
            else
                bashio::log.warning "Failed to migrate from: $legacy_path"
            fi
        fi
    done

    if [ "$migrated" = false ]; then
        bashio::log.info "No existing Codex files found to migrate"
    fi
}

ensure_codex_config() {
    local config_file="${CODEX_HOME}/config.toml"
    touch "$config_file"
    chmod 600 "$config_file"

    if ! grep -Eq '^model_instructions_file[[:space:]]*=' "$config_file"; then
        {
            printf '\n'
            printf 'model_instructions_file = "/data/home/AGENTS.md"\n'
        } >> "$config_file"
        bashio::log.info "Configured Codex to load /data/home/AGENTS.md"
    fi
}

install_tools() {
    bashio::log.info "Verifying required runtime tools..."
    for cmd in bash curl jq tmux ttyd npm codex; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            bashio::log.error "Required command not found: $cmd"
            exit 1
        fi
    done
    bashio::log.info "Required tools are available"
}

get_codex_cli_version() {
    codex --version 2>/dev/null | awk '{print $NF}' || true
}

is_valid_codex_cli_target() {
    [[ "$1" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]
}

apply_pinned_codex_cli_version() {
    local version_file="/data/codex-cli-version"
    local target current

    if [ ! -s "$version_file" ]; then
        return
    fi

    target="$(tr -d '[:space:]' < "$version_file")"
    if [ -z "$target" ]; then
        return
    fi

    if ! is_valid_codex_cli_target "$target"; then
        bashio::log.warning "Ignoring invalid pinned Codex CLI version: $target"
        return
    fi

    current="$(get_codex_cli_version)"
    if [ "$current" = "$target" ]; then
        bashio::log.info "Pinned Codex CLI version already installed: $target"
        return
    fi

    bashio::log.info "Installing pinned Codex CLI version: $target"
    if npm install -g "@openai/codex@$target"; then
        npm cache clean --force >/dev/null 2>&1 || true
        bashio::log.info "Codex CLI updated to $(get_codex_cli_version)"
    else
        bashio::log.warning "Failed to install pinned Codex CLI version: $target"
    fi
}

setup_helpers() {
    if [ -f "/opt/scripts/codex-session-picker.sh" ]; then
        cp /opt/scripts/codex-session-picker.sh /usr/local/bin/codex-session-picker
        chmod 755 /usr/local/bin/codex-session-picker
        bashio::log.info "Session picker script installed successfully"
    fi

    if [ -f "/opt/scripts/persist-install.sh" ]; then
        cp /opt/scripts/persist-install.sh /usr/local/bin/persist-install
        chmod 755 /usr/local/bin/persist-install
        bashio::log.info "Persist-install script installed successfully"
    fi

    if [ -f "/opt/scripts/codex-update.sh" ]; then
        cp /opt/scripts/codex-update.sh /usr/local/bin/codex-update
        chmod 755 /usr/local/bin/codex-update
        bashio::log.info "Codex update script installed successfully"
    fi

    if [ -f "/opt/scripts/codex-update-scheduler.sh" ]; then
        cp /opt/scripts/codex-update-scheduler.sh /usr/local/bin/codex-update-scheduler
        chmod 755 /usr/local/bin/codex-update-scheduler
        bashio::log.info "Codex update scheduler installed successfully"
    fi

    if [ -f "/opt/scripts/welcome.sh" ]; then
        cp /opt/scripts/welcome.sh /usr/local/bin/welcome
        chmod 755 /usr/local/bin/welcome
        bashio::log.info "Welcome script installed successfully"
    fi

    if [ -f "/opt/scripts/ha-context.sh" ]; then
        cp /opt/scripts/ha-context.sh /usr/local/bin/ha-context
        chmod 755 /usr/local/bin/ha-context
        bashio::log.info "HA context script installed successfully"
    fi

    cat > /usr/local/bin/codex-ha <<'SCRIPT'
#!/bin/bash
exec codex --cd /config --sandbox workspace-write --ask-for-approval on-request "$@"
SCRIPT
    chmod 755 /usr/local/bin/codex-ha

    bashio::addon.version > /opt/scripts/app-version 2>/dev/null || echo "unknown" > /opt/scripts/app-version
}

install_persistent_packages() {
    bashio::log.info "Checking for persistent packages..."

    local persist_config="/data/persistent-packages.json"
    local apk_packages=""
    local pip_packages=""

    if bashio::config.has_value 'persistent_apk_packages'; then
        apk_packages="$(bashio::config 'persistent_apk_packages')"
    fi

    if bashio::config.has_value 'persistent_pip_packages'; then
        pip_packages="$(bashio::config 'persistent_pip_packages')"
    fi

    if [ -f "$persist_config" ]; then
        local local_apk local_pip
        local_apk=$(jq -r '.apk_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        local_pip=$(jq -r '.pip_packages | join(" ")' "$persist_config" 2>/dev/null || echo "")
        apk_packages="$apk_packages $local_apk"
        pip_packages="$pip_packages $local_pip"
    fi

    apk_packages=$(echo "$apk_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)
    pip_packages=$(echo "$pip_packages" | tr ' ' '\n' | sort -u | tr '\n' ' ' | xargs)

    if [ -n "$apk_packages" ]; then
        bashio::log.info "Installing persistent APK packages: $apk_packages"
        # shellcheck disable=SC2086
        apk add --no-cache $apk_packages || bashio::log.warning "Some APK packages failed to install"
    fi

    if [ -n "$pip_packages" ]; then
        bashio::log.info "Installing persistent pip packages: $pip_packages"
        # shellcheck disable=SC2086
        pip3 install --break-system-packages --no-cache-dir $pip_packages || bashio::log.warning "Some pip packages failed to install"
    fi

    if [ -z "$apk_packages" ] && [ -z "$pip_packages" ]; then
        bashio::log.info "No persistent packages configured"
    fi
}

generate_ha_context() {
    local ha_smart_context
    ha_smart_context=$(bashio::config 'ha_smart_context' 'true')

    if [ "$ha_smart_context" = "true" ]; then
        bashio::log.info "Generating Home Assistant context for Codex sessions..."
        if /usr/local/bin/ha-context 2>&1 | while IFS= read -r line; do bashio::log.info "$line"; done; then
            bashio::log.info "HA context generated successfully"
        else
            bashio::log.warning "HA context generation had issues, continuing"
        fi
    else
        bashio::log.info "HA Smart Context disabled in configuration"
    fi
}

setup_ha_mcp() {
    if [ -f "/opt/scripts/setup-ha-mcp.sh" ]; then
        bashio::log.info "Setting up Home Assistant MCP integration..."
        chmod 755 /opt/scripts/setup-ha-mcp.sh
        source /opt/scripts/setup-ha-mcp.sh
        configure_ha_mcp_server || bashio::log.warning "ha_mcp setup encountered issues but continuing"
    else
        bashio::log.info "ha_mcp setup script not found, skipping MCP integration"
    fi
}

start_codex_update_scheduler() {
    local enabled schedule_time schedule_days log_file

    enabled=$(bashio::config 'codex_auto_update' 'true')
    if [ "$enabled" != "true" ]; then
        bashio::log.info "Codex CLI scheduled updates disabled"
        return
    fi

    if ! command -v codex-update-scheduler >/dev/null 2>&1; then
        bashio::log.warning "Codex update scheduler not found; scheduled updates disabled"
        return
    fi

    schedule_time=$(bashio::config 'codex_auto_update_time' '03:30')
    schedule_days=$(bashio::config 'codex_auto_update_days' 'daily')
    log_file="/data/codex-update-scheduler.log"

    bashio::log.info "Starting Codex CLI scheduled updates: ${schedule_days} at ${schedule_time}"
    CODEX_UPDATE_SCHEDULE_TIME="$schedule_time" \
    CODEX_UPDATE_SCHEDULE_DAYS="$schedule_days" \
    CODEX_UPDATE_TARGET="latest" \
    codex-update-scheduler >> "$log_file" 2>&1 &
}

get_codex_launch_command() {
    local auto_launch_codex welcome_prefix
    auto_launch_codex=$(bashio::config 'auto_launch_codex' 'true')
    welcome_prefix=""

    if [ -f /usr/local/bin/welcome ]; then
        welcome_prefix="welcome; "
    fi

    if [ "$auto_launch_codex" = "true" ]; then
        echo "${welcome_prefix}tmux new-session -A -s codex 'codex-ha'"
    else
        if [ -f /usr/local/bin/codex-session-picker ]; then
            echo "${welcome_prefix}/usr/local/bin/codex-session-picker"
        else
            bashio::log.warning "Session picker not found, falling back to auto-launch"
            echo "${welcome_prefix}tmux new-session -A -s codex 'codex-ha'"
        fi
    fi
}

start_web_terminal() {
    local port=7681 launch_command auto_launch_codex ttyd_theme
    launch_command=$(get_codex_launch_command)
    auto_launch_codex=$(bashio::config 'auto_launch_codex' 'true')

    bashio::log.info "Starting web terminal on port ${port}..."
    bashio::log.info "CODEX_HOME=${CODEX_HOME}"
    bashio::log.info "HOME=${HOME}"
    bashio::log.info "Auto-launch Codex: ${auto_launch_codex}"

    export TTYD=1

    ttyd_theme='{"background":"#101418","foreground":"#d7dee8","cursor":"#3fb950","cursorAccent":"#101418","selectionBackground":"#263545","selectionForeground":"#d7dee8","black":"#0b0f14","red":"#ff6b6b","green":"#3fb950","yellow":"#d29922","blue":"#58a6ff","magenta":"#bc8cff","cyan":"#39c5cf","white":"#b7c0ca","brightBlack":"#52606d","brightRed":"#ff8585","brightGreen":"#56d364","brightYellow":"#e3b341","brightBlue":"#79c0ff","brightMagenta":"#d2a8ff","brightCyan":"#56d4dd","brightWhite":"#f0f6fc"}'

    exec ttyd \
        --port "${port}" \
        --interface 0.0.0.0 \
        --writable \
        --ping-interval 30 \
        --client-option enableReconnect=true \
        --client-option reconnect=10 \
        --client-option reconnectInterval=5 \
        --client-option scrollback=50000 \
        --client-option "theme=${ttyd_theme}" \
        --client-option fontSize=14 \
        bash -c "$launch_command"
}

run_health_check() {
    if [ -f "/opt/scripts/health-check.sh" ]; then
        bashio::log.info "Running system health check..."
        chmod 755 /opt/scripts/health-check.sh
        /opt/scripts/health-check.sh || bashio::log.warning "Some health checks failed but continuing"
    fi
}

main() {
    bashio::log.info "Initializing Codex Terminal app..."
    run_health_check
    init_environment
    install_tools
    apply_pinned_codex_cli_version
    setup_helpers
    install_persistent_packages
    generate_ha_context
    setup_ha_mcp
    start_codex_update_scheduler
    start_web_terminal
}

main "$@"
