#!/bin/bash
# Run only inside a disposable add-on image: this writes /data and /etc/passwd.
set -euo pipefail
[[ "${CODEX_REMOTE_TEST_CONTAINER:-}" == 1 ]] || { echo 'Disposable container required' >&2; exit 1; }
export HOME=/data/home CODEX_HOME=/data/.codex XDG_CONFIG_HOME=/data/.config
export XDG_CACHE_HOME=/data/.cache XDG_STATE_HOME=/data/.local/state XDG_DATA_HOME=/data/.local/share
mkdir -p "$HOME" /config
bashio::config.true() { [[ "$1" == ssh_enabled ]]; }
bashio::log.info() { echo "$*"; }
bashio::log.error() { echo "$*" >&2; }
ssh-keygen -q -t ed25519 -N '' -f /tmp/client-key
jq -n --arg key "$(cat /tmp/client-key.pub)" '{ssh_authorized_keys:[$key]}' > /data/options.json
source /opt/scripts/setup-remote-access.sh
setup_remote_access
[[ "$(stat -c '%a' /run/codex-remote-env)" == 600 ]]
[[ "$(stat -c '%a' /data/ssh/authorized_keys)" == 600 ]]
[[ "$(herdr --version)" == 'herdr 0.9.1' ]]
settings=$(/usr/sbin/sshd -T -f /data/ssh/sshd_config)
grep -qx 'passwordauthentication no' <<< "$settings"
grep -qx 'authenticationmethods publickey' <<< "$settings"
grep -qx 'allowtcpforwarding local' <<< "$settings"
printf '[127.0.0.1]:2222 %s\n' "$(cat /data/ssh/ssh_host_ed25519_key.pub)" > /tmp/known_hosts
ssh_args=(-o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/tmp/known_hosts -o IdentitiesOnly=yes -i /tmp/client-key -p 2222 root@127.0.0.1)
[[ "$(ssh "${ssh_args[@]}" 'printf "%s|%s" "$HOME" "$CODEX_HOME"')" == '/data/home|/data/.codex' ]]
[[ "$(ssh "${ssh_args[@]}" 'herdr --version')" == 'herdr 0.9.1' ]]
ssh-keygen -q -t ed25519 -N '' -f /tmp/wrong-key
if ssh -o BatchMode=yes -o StrictHostKeyChecking=yes -o UserKnownHostsFile=/tmp/known_hosts -o IdentitiesOnly=yes -i /tmp/wrong-key -p 2222 root@127.0.0.1 true; then
    echo 'Unauthorized key accepted' >&2; exit 1
fi
key_before=$(sha256sum /data/ssh/ssh_host_ed25519_key)
kill "$(cat /run/codex-sshd.pid)"
sleep 1
setup_remote_access
[[ "$(sha256sum /data/ssh/ssh_host_ed25519_key)" == "$key_before" ]]
ssh "${ssh_args[@]}" true
echo 'Remote access checks passed'
