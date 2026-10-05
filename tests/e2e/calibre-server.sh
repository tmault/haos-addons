#!/usr/bin/env bash
# Builds and serves the genuine add-on with an isolated, empty test library.
set -euo pipefail
cd "$(dirname "$0")/../.."
docker_bin=${DOCKER_BIN:-docker}
image=${CALIBRE_TEST_IMAGE:-haos-e2e-calibre}
name="haos-e2e-calibre-${$}"
config_volume="${name}-config"
share_volume="${name}-share"
data_volume="${name}-data"
state_file=".e2e-runtime/calibre-${CALIBRE_PORT:-18083}.json"
cleanup() {
  rm -f "$state_file"
  "$docker_bin" rm -fv "$name" >/dev/null 2>&1 || true
  "$docker_bin" volume rm "$config_volume" "$share_volume" "$data_volume" >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM
"$docker_bin" build -t "$image" calibre_web_automated
for volume in "$config_volume" "$share_volume" "$data_volume"; do
  "$docker_bin" volume create "$volume" >/dev/null
done
# Seed only upstream's empty database, configure its HA library path and local
# test credentials. All books are subsequently created through the browser.
"$docker_bin" run --rm --entrypoint /bin/bash \
  -v "$config_volume:/config" -v "$share_volume:/share" -v "$data_volume:/data" "$image" -c '
mkdir -p /share/calibre-web-automated/library
cp /app/calibre-web-automated/empty_library/metadata.db /share/calibre-web-automated/library/metadata.db
cp /app/calibre-web-automated/empty_library/app.db /config/app.db
printf "{}\n" >/data/options.json
python3 - <<"PY"
import sqlite3
from werkzeug.security import generate_password_hash
conn = sqlite3.connect("/config/app.db")
conn.execute("UPDATE settings SET config_calibre_dir=?, config_uploading=1, config_anonbrowse=0", ("/share/calibre-web-automated/library",))
conn.execute("UPDATE user SET password=? WHERE name=?", (generate_password_hash("admin123"), "admin"))
conn.commit()
PY
chown -R 1000:1000 /config /share
'
network_args=(-p "127.0.0.1:${CALIBRE_PORT:-18083}:8083")
if [[ "${CALIBRE_NETWORK:-bridge}" == host ]]; then
  network_args=(--network host -e "CWA_PORT_OVERRIDE=${CALIBRE_PORT:-18083}")
fi
"$docker_bin" run -d --name "$name" "${network_args[@]}" \
  -v "$config_volume:/config" -v "$share_volume:/share" -v "$data_volume:/data" "$image" >/dev/null
for attempt in $(seq 1 180); do
  if curl -fsS "http://127.0.0.1:${CALIBRE_PORT:-18083}/login" >/dev/null 2>&1; then
    break
  fi
  if [[ "$attempt" == 180 ]]; then
    "$docker_bin" logs "$name"
    exit 1
  fi
  sleep 2
done
mkdir -p .e2e-runtime
printf '{"name":"%s","url":"http://127.0.0.1:%s"}\n' "$name" "${CALIBRE_PORT:-18083}" >"$state_file"
"$docker_bin" logs -f "$name" &
log_pid=$!
# A deliberate test restart preserves volumes and must not end the fixture.
while true; do
  "$docker_bin" wait "$name" &
  wait "$!"
  sleep 3 &
  wait "$!"
  status=$("$docker_bin" inspect --format '{{.State.Status}}' "$name" 2>/dev/null || true)
  [[ "$status" == running || "$status" == restarting ]] || break
done
kill "$log_pid" 2>/dev/null || true
