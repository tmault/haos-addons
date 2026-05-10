#!/bin/bash

set -e

CONFIG_FILE="/data/persistent-packages.json"

ensure_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo '{"apk_packages":[],"pip_packages":[]}' > "$CONFIG_FILE"
    fi
}

list_packages() {
    ensure_config
    echo "APK packages:"
    jq -r '.apk_packages[]? | "- " + .' "$CONFIG_FILE"
    echo ""
    echo "pip packages:"
    jq -r '.pip_packages[]? | "- " + .' "$CONFIG_FILE"
}

add_packages() {
    local kind="$1"
    shift

    if [ "$#" -eq 0 ]; then
        echo "No packages supplied" >&2
        exit 1
    fi

    ensure_config

    local key tmp
    case "$kind" in
        apk) key="apk_packages" ;;
        pip) key="pip_packages" ;;
        *)
            echo "Unknown package type: $kind" >&2
            exit 1
            ;;
    esac

    tmp=$(mktemp)
    jq --arg key "$key" --args '
        .[$key] = ((.[$key] + $ARGS.positional) | unique)
    ' "$CONFIG_FILE" "$@" > "$tmp"
    mv "$tmp" "$CONFIG_FILE"

    echo "Saved $kind packages. They will be installed now and on restart."

    case "$kind" in
        apk)
            apk add --no-cache "$@"
            ;;
        pip)
            pip3 install --break-system-packages --no-cache-dir "$@"
            ;;
    esac
}

usage() {
    echo "Usage:"
    echo "  persist-install list"
    echo "  persist-install apk PACKAGE [PACKAGE...]"
    echo "  persist-install pip PACKAGE [PACKAGE...]"
}

case "${1:-}" in
    list)
        list_packages
        ;;
    apk|pip)
        kind="$1"
        shift
        add_packages "$kind" "$@"
        ;;
    *)
        usage
        exit 1
        ;;
esac
