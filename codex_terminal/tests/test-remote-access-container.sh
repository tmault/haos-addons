#!/usr/bin/env bash
# Build the genuine add-on, then run SSH checks in a disposable filesystem.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
docker_bin=${DOCKER_BIN:-docker}
build_arch=${BUILD_ARCH:-amd64}
image=${CODEX_REMOTE_TEST_IMAGE:-haos-codex-remote-test:local}
build_from=${BUILD_FROM:-ghcr.io/home-assistant/${build_arch}-base:3.21}
build_args=()
if [[ -n ${CODEX_TEST_BUILD_NETWORK:-} ]]; then
    build_args+=(--network "$CODEX_TEST_BUILD_NETWORK")
fi
"$docker_bin" build "${build_args[@]}" --build-arg "BUILD_FROM=$build_from" \
    --build-arg "BUILD_ARCH=$build_arch" -t "$image" "$root"
# No ports published or persistent directories mounted. Even /etc/passwd and
# /data mutations disappear with the container. Only the test is mounted read-only.
"$docker_bin" run --rm --entrypoint /bin/bash \
    -e CODEX_REMOTE_TEST_CONTAINER=1 \
    --mount "type=bind,source=$root/tests/test-remote-access.sh,target=/tmp/test-remote-access.sh,readonly" \
    "$image" /tmp/test-remote-access.sh
