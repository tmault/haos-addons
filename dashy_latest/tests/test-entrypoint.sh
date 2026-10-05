#!/usr/bin/env bash
set -euo pipefail
repo_dir=$(cd "$(dirname "$0")/../.." && pwd)
entrypoint="$repo_dir/dashy_latest/rootfs/usr/local/bin/ha-dashy-entrypoint"
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
printf 'pageInfo:\n  title: Bundled default\nsections: []\n' > "$temp_dir/default.yml"
passed=0
pass() { passed=$((passed + 1)); printf 'PASS %s\n' "$1"; }

USER_DATA_DIR="$temp_dir/new config" DASHY_DEFAULT_CONFIG="$temp_dir/default.yml" sh "$entrypoint" sh -c 'test -f "$USER_DATA_DIR/conf.yml"'
cmp "$temp_dir/default.yml" "$temp_dir/new config/conf.yml"
pass 'first start seeds configured directory, including paths with spaces'

printf 'user changes\n' > "$temp_dir/new config/conf.yml"
USER_DATA_DIR="$temp_dir/new config" DASHY_DEFAULT_CONFIG="$temp_dir/missing.yml" sh "$entrypoint" true
[[ $(cat "$temp_dir/new config/conf.yml") == 'user changes' ]]
pass 'restart preserves user configuration without requiring bundled default'

: > "$temp_dir/new config/conf.yml"
USER_DATA_DIR="$temp_dir/new config" DASHY_DEFAULT_CONFIG="$temp_dir/default.yml" sh "$entrypoint" true
[[ ! -s "$temp_dir/new config/conf.yml" ]]
pass 'existing empty file is preserved rather than silently overwritten'

if USER_DATA_DIR="$temp_dir/no default" DASHY_DEFAULT_CONFIG="$temp_dir/missing.yml" sh "$entrypoint" touch "$temp_dir/command-ran" 2>/dev/null; then exit 1; fi
[[ ! -e "$temp_dir/command-ran" ]]
pass 'missing bundled default prevents application startup'

printf 'blocked' > "$temp_dir/not-a-directory"
if USER_DATA_DIR="$temp_dir/not-a-directory" DASHY_DEFAULT_CONFIG="$temp_dir/default.yml" sh "$entrypoint" true 2>/dev/null; then exit 1; fi
pass 'invalid data directory fails startup'

set +e
USER_DATA_DIR="$temp_dir/new config" sh "$entrypoint" sh -c 'exit 37'
status=$?
set -e
[[ $status == 37 ]]
pass 'application exit status propagates'

USER_DATA_DIR="$temp_dir/new config" sh "$entrypoint" sh -c 'printf "%s" "$1"' sh 'argument with spaces' > "$temp_dir/arg"
[[ $(cat "$temp_dir/arg") == 'argument with spaces' ]]
pass 'application arguments retain boundaries'
printf '%s startup regression cases passed\n' "$passed"
