#!/usr/bin/env bash
set -euo pipefail
export DASHY_E2E_AUTH=true DASHY_E2E_PORT=18081
exec bash "$(dirname "$0")/dashy-server.sh"
