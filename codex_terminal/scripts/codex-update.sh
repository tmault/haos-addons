#!/bin/bash

set -euo pipefail

PACKAGE="@openai/codex"
VERSION_FILE="${CODEX_CLI_VERSION_FILE:-/data/codex-cli-version}"

usage() {
    cat <<'EOF'
Usage:
  codex-update [VERSION_OR_TAG]
  codex-update --no-persist [VERSION_OR_TAG]
  codex-update --clear-pin

Examples:
  codex-update
  codex-update latest
  codex-update 0.130.0
  codex-update --clear-pin

Updates the globally installed OpenAI Codex CLI in the running add-on
container. The current Codex process keeps using the version it started
with; restart Codex or open a new terminal session after updating.
EOF
}

log() {
    echo "$*"
}

die() {
    echo "Error: $*" >&2
    exit 1
}

validate_target() {
    local target="$1"

    if [[ ! "$target" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
        die "Invalid version or dist-tag: $target"
    fi
}

get_installed_version() {
    codex --version 2>/dev/null | awk '{print $NF}' || true
}

main() {
    local persist="true"
    local clear_pin="false"
    local target="latest"

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            --no-persist)
                persist="false"
                shift
                ;;
            --clear-pin)
                clear_pin="true"
                shift
                ;;
            -*)
                die "Unknown option: $1"
                ;;
            *)
                target="$1"
                shift
                ;;
        esac
    done

    if [ "$clear_pin" = "true" ]; then
        rm -f "$VERSION_FILE"
        log "Removed saved Codex CLI version pin."
        exit 0
    fi

    validate_target "$target"

    command -v npm >/dev/null 2>&1 || die "npm is not installed"
    command -v codex >/dev/null 2>&1 || die "codex is not installed"

    local before resolved after
    before="$(get_installed_version)"

    log "Current Codex CLI: ${before:-unknown}"
    log "Resolving ${PACKAGE}@${target}..."
    resolved="$(npm view "${PACKAGE}@${target}" version)"
    [ -n "$resolved" ] || die "Could not resolve ${PACKAGE}@${target}"

    if [ "$before" = "$resolved" ]; then
        log "Codex CLI is already at ${resolved}."
    else
        log "Installing Codex CLI ${resolved}..."
        npm install -g "${PACKAGE}@${resolved}"
        npm cache clean --force >/dev/null 2>&1 || true
    fi

    after="$(get_installed_version)"
    log "Codex CLI after update: ${after:-unknown}"

    if [ "$persist" = "true" ]; then
        mkdir -p "$(dirname "$VERSION_FILE")"
        printf '%s\n' "$resolved" > "$VERSION_FILE"
        log "Pinned Codex CLI ${resolved} for future add-on starts."
    else
        log "Persistence skipped."
    fi

    log "Restart Codex or open a new terminal session to use the updated CLI."
}

main "$@"
