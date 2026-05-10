#!/bin/bash

TMUX_SESSION_NAME="codex"
CODEX_BASE_COMMAND="codex-ha"

GREEN='\033[0;32m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

show_banner() {
    clear
    echo ""
    echo -e "  ${GREEN}============================================================${NC}"
    echo -e "  ${WHITE}Codex Terminal${NC} ${DIM}- Session Picker${NC}"
    echo -e "  ${GREEN}============================================================${NC}"
    echo ""
}

check_existing_session() {
    tmux has-session -t "$TMUX_SESSION_NAME" 2>/dev/null
}

show_menu() {
    echo "Choose your Codex session type:"
    echo ""

    if check_existing_session; then
        echo "  0) Reconnect to existing session"
        echo ""
    fi

    echo "  1) New interactive session"
    echo "  2) Resume most recent session"
    echo "  3) Pick a session to resume"
    echo "  4) Custom Codex command"
    echo "  5) Log in or check login status"
    echo "  6) Bash shell"
    echo "  7) Exit"
    echo ""
}

get_user_choice() {
    local choice default
    default="1"
    if check_existing_session; then
        default="0"
    fi

    printf "Enter your choice [0-7] (default: %s): " "$default" >&2
    read -r choice
    [ -z "$choice" ] && choice="$default"
    echo "$choice" | tr -d '[:space:]'
}

attach_existing_session() {
    echo "Reconnecting to existing Codex session..."
    sleep 1
    exec tmux attach-session -t "$TMUX_SESSION_NAME"
}

reset_session() {
    if check_existing_session; then
        tmux kill-session -t "$TMUX_SESSION_NAME" 2>/dev/null
    fi
}

launch_new() {
    echo "Starting new Codex session..."
    reset_session
    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_BASE_COMMAND"
}

launch_resume_last() {
    echo "Resuming most recent Codex session..."
    reset_session
    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_BASE_COMMAND resume --last"
}

launch_resume_picker() {
    echo "Opening Codex session picker..."
    reset_session
    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_BASE_COMMAND resume"
}

launch_custom() {
    echo ""
    echo "Enter Codex arguments after the default workspace flags."
    echo "Example: exec --skip-git-repo-check \"summarize this Home Assistant config\""
    echo -n "> codex-ha "
    read -r custom_args

    if [ -z "$custom_args" ]; then
        launch_new
    fi

    reset_session
    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" "$CODEX_BASE_COMMAND $custom_args"
}

launch_login() {
    echo "Starting Codex login..."
    reset_session
    sleep 1
    exec tmux new-session -s "$TMUX_SESSION_NAME" "codex login"
}

launch_shell() {
    echo "Dropping to bash shell..."
    echo "Tip: run 'codex-ha' to start Codex in /config with HA MCP configured."
    sleep 1
    exec bash
}

main() {
    while true; do
        show_banner
        show_menu
        choice=$(get_user_choice)

        case "$choice" in
            0)
                if check_existing_session; then
                    attach_existing_session
                else
                    echo "No existing session found"
                    sleep 1
                fi
                ;;
            1) launch_new ;;
            2) launch_resume_last ;;
            3) launch_resume_picker ;;
            4) launch_custom ;;
            5) launch_login ;;
            6) launch_shell ;;
            7) exit 0 ;;
            *)
                echo "Invalid choice: $choice"
                printf "Press Enter to continue..." >&2
                read -r
                ;;
        esac
    done
}

trap 'echo ""; exit 0' EXIT INT TERM
main "$@"
