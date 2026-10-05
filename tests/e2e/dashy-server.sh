#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
: "${DASHY_SOURCE_DIR:?Set DASHY_SOURCE_DIR to an installed, built upstream Dashy checkout}"
source_dir=$(cd "$DASHY_SOURCE_DIR" && pwd)
if [[ ! -f "$source_dir/dist/index.html" ]] || ! find "$source_dir/dist" -name '*.js' -print -quit | read -r _; then
  printf 'Dashy production build missing: run npm run build in %s\n' "$source_dir" >&2
  exit 1
fi

# Isolated writable data per run: never alter the checkout's bundled config.
run_dir=$(mktemp -d "${TMPDIR:-/tmp}/haos-dashy-e2e.XXXXXX")
cleanup() {
  if [[ -n ${server_pid:-} ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$run_dir"
}
trap cleanup EXIT
trap 'exit 143' TERM
trap 'exit 130' INT
cat > "$run_dir/default.yml" <<'YAML'
pageInfo:
  title: HAOS Dashy E2E
  description: Real upstream dashboard running through the add-on entrypoint
  navLinks:
    - title: Config source
      path: http://127.0.0.1:18080/conf.yml
      target: sametab
appConfig:
  theme: colorful
  language: en
  disableUpdateChecks: true
  disableContextMenu: false
sections:
  - name: Home Services
    items:
      - title: Configuration file
        description: Persisted dashboard configuration
        url: /conf.yml
        target: sametab
      - title: Dashy health
        description: Live upstream health endpoint
        url: /healthz
        target: sametab
YAML
if [[ ${DASHY_E2E_AUTH:-false} == true ]]; then
  # Disposable public test credentials: both users have password 12345.
  sed -i '/  theme: colorful/a\  disableConfigurationForNonAdmin: true\n  enableGuestAccess: false\n  auth:\n    users:\n      - user: e2e-admin\n        hash: 5994471ABB01112AFCC18159F6CC74B4F511B99806DA59B3CAF5A9C173CACFC5\n        type: admin\n      - user: e2e-reader\n        hash: 5994471ABB01112AFCC18159F6CC74B4F511B99806DA59B3CAF5A9C173CACFC5\n        type: normal' "$run_dir/default.yml"
fi
export USER_DATA_DIR="$run_dir/config"
export DASHY_DEFAULT_CONFIG="$run_dir/default.yml"
export PORT=${DASHY_E2E_PORT:-18080} HOST=127.0.0.1 IS_DOCKER=true NODE_ENV=production
cd "$source_dir"
sh "$repo_dir/dashy_latest/rootfs/usr/local/bin/ha-dashy-entrypoint" node server.js &
server_pid=$!
wait "$server_pid"
