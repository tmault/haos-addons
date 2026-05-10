#!/bin/bash

set -euo pipefail

SCHEDULE_TIME="${CODEX_UPDATE_SCHEDULE_TIME:-03:30}"
SCHEDULE_DAYS="${CODEX_UPDATE_SCHEDULE_DAYS:-daily}"
UPDATE_TARGET="${CODEX_UPDATE_TARGET:-latest}"
LAST_RUN_FILE="${CODEX_UPDATE_LAST_RUN_FILE:-/data/codex-update-last-run}"
CHECK_INTERVAL_SECONDS="${CODEX_UPDATE_CHECK_INTERVAL_SECONDS:-60}"

usage() {
    cat <<'EOF'
Usage:
  codex-update-scheduler
  codex-update-scheduler --run-once

Environment:
  CODEX_UPDATE_SCHEDULE_TIME    HH:MM local time, default 03:30
  CODEX_UPDATE_SCHEDULE_DAYS    daily, weekdays, weekends, or mon,tue,...
  CODEX_UPDATE_TARGET           npm version or dist-tag, default latest

Runs codex-update at the configured local time and records the last
successful update date so the schedule only fires once per day.
EOF
}

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*"
}

normalize() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

normalize_day() {
    local day
    day="$(normalize "$1")"

    case "$day" in
        1|mon|monday) echo "mon" ;;
        2|tue|tues|tuesday) echo "tue" ;;
        3|wed|wednesday) echo "wed" ;;
        4|thu|thur|thurs|thursday) echo "thu" ;;
        5|fri|friday) echo "fri" ;;
        6|sat|saturday) echo "sat" ;;
        7|sun|sunday) echo "sun" ;;
        *) echo "" ;;
    esac
}

validate_time() {
    local time="$1" hour minute

    [[ "$time" =~ ^[0-9]{2}:[0-9]{2}$ ]] || return 1

    hour="${time%:*}"
    minute="${time#*:}"

    [ "$hour" -ge 0 ] && [ "$hour" -le 23 ] && [ "$minute" -ge 0 ] && [ "$minute" -le 59 ]
}

validate_days() {
    local schedule="$1" item

    schedule="$(normalize "$schedule")"
    case "$schedule" in
        daily|everyday|all|nightly|weekdays|weekends)
            return 0
            ;;
    esac

    IFS=',' read -r -a items <<< "$schedule"
    for item in "${items[@]}"; do
        [ -n "$(normalize_day "$item")" ] || return 1
    done
}

day_matches() {
    local schedule="$1" day="$2" item

    schedule="$(normalize "$schedule")"
    day="$(normalize_day "$day")"

    case "$schedule" in
        daily|everyday|all|nightly)
            return 0
            ;;
        weekdays)
            [[ "$day" =~ ^(mon|tue|wed|thu|fri)$ ]]
            return
            ;;
        weekends)
            [[ "$day" =~ ^(sat|sun)$ ]]
            return
            ;;
    esac

    IFS=',' read -r -a items <<< "$schedule"
    for item in "${items[@]}"; do
        if [ "$(normalize_day "$item")" = "$day" ]; then
            return 0
        fi
    done

    return 1
}

current_date() {
    echo "${CODEX_UPDATE_NOW_DATE:-$(date '+%F')}"
}

current_time() {
    echo "${CODEX_UPDATE_NOW_TIME:-$(date '+%H:%M')}"
}

current_day() {
    echo "${CODEX_UPDATE_NOW_DAY:-$(date '+%a')}"
}

last_run_date() {
    cat "$LAST_RUN_FILE" 2>/dev/null || true
}

record_run_date() {
    mkdir -p "$(dirname "$LAST_RUN_FILE")"
    printf '%s\n' "$1" > "$LAST_RUN_FILE"
}

run_once() {
    local today now day last_run

    if ! validate_time "$SCHEDULE_TIME"; then
        log "Invalid Codex CLI update time: $SCHEDULE_TIME"
        return 1
    fi

    if ! validate_days "$SCHEDULE_DAYS"; then
        log "Invalid Codex CLI update days: $SCHEDULE_DAYS"
        return 1
    fi

    today="$(current_date)"
    now="$(current_time)"
    day="$(current_day)"

    if [ "$now" != "$SCHEDULE_TIME" ]; then
        return 0
    fi

    if ! day_matches "$SCHEDULE_DAYS" "$day"; then
        return 0
    fi

    last_run="$(last_run_date)"
    if [ "$last_run" = "$today" ]; then
        return 0
    fi

    log "Running scheduled Codex CLI update for ${today} ${now} (${SCHEDULE_DAYS})"
    if codex-update "$UPDATE_TARGET"; then
        record_run_date "$today"
        log "Scheduled Codex CLI update completed"
        return 0
    fi

    log "Scheduled Codex CLI update failed"
    return 1
}

main() {
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        --run-once)
            run_once
            exit $?
            ;;
        "")
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac

    log "Codex CLI update scheduler enabled: ${SCHEDULE_DAYS} at ${SCHEDULE_TIME}"

    while true; do
        run_once || log "Codex CLI update scheduler check failed"
        sleep "$CHECK_INTERVAL_SECONDS"
    done
}

main "$@"
