#!/bin/bash

set -e

log() {
    echo "$1"
}

log "========================================="
log "Codex Terminal Health Check"
log "========================================="

log "System resources:"
free -m | awk '/Mem:/ {print "Memory: " $7 "MB free of " $2 "MB total"}' || true
df -m /data | awk 'NR==2 {print "Disk space in /data: " $4 "MB free"}' || true

log "Runtime commands:"
for cmd in node npm codex uvx ttyd tmux jq curl; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "- $cmd: found"
    else
        echo "- $cmd: missing"
    fi
done

log "Versions:"
node --version 2>/dev/null || true
npm --version 2>/dev/null || true
codex --version 2>/dev/null || true

log "Network checks:"
if getent hosts registry.npmjs.org >/dev/null 2>&1; then
    echo "- DNS resolution: ok"
else
    echo "- DNS resolution: failed"
fi

openai_status=$(curl -sS -m 10 -o /dev/null -w "%{http_code}" https://api.openai.com/v1/models 2>/dev/null || echo "000")
if [ "$openai_status" != "000" ]; then
    echo "- OpenAI API reachable (HTTP ${openai_status})"
else
    echo "- OpenAI API unreachable"
fi

log "========================================="
log "Health check complete"
