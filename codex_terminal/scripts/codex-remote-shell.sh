#!/bin/bash
set -e
# SSH sessions need the same persistent paths and HA context as the web terminal.
source /run/codex-remote-env
if [ "$#" -eq 0 ]; then
    cd /config
    exec /bin/bash -l
fi
exec /bin/bash "$@"
