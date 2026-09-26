#!/bin/bash

setup_remote_access() {
if ! bashio::config.true 'ssh_enabled'; then
    return 0
fi

install -d -m 700 /data/ssh
# Only public keys belong in add-on options. Never accept password authentication.
jq -r '.ssh_authorized_keys[]?' /data/options.json > /data/ssh/authorized_keys
chmod 600 /data/ssh/authorized_keys
if ! ssh-keygen -l -f /data/ssh/authorized_keys >/dev/null 2>&1; then
    bashio::log.error "SSH enabled without a valid authorized public key"
    exit 1
fi
if [ ! -f /data/ssh/ssh_host_ed25519_key ]; then
    ssh-keygen -q -t ed25519 -N '' -f /data/ssh/ssh_host_ed25519_key
fi

install -m 755 /opt/scripts/codex-remote-shell.sh /usr/local/bin/codex-remote-shell
# Persist only the environment needed by Codex and its HA helpers, readable by root.
(umask 077; : > /run/codex-remote-env)
for name in HOME CODEX_HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_STATE_HOME XDG_DATA_HOME PATH SUPERVISOR_TOKEN HASSIO_TOKEN; do
    if printenv "$name" >/dev/null; then
        printf 'export %s=%q\n' "$name" "${!name}" >> /run/codex-remote-env
    fi
done
sed -i 's|^root:[^:]*:0:0:[^:]*:[^:]*:[^:]*$|root:x:0:0:root:/data/home:/usr/local/bin/codex-remote-shell|' /etc/passwd
if ! grep -qxF /usr/local/bin/codex-remote-shell /etc/shells; then
    echo /usr/local/bin/codex-remote-shell >> /etc/shells
fi

cat > /data/ssh/sshd_config <<'CONF'
Port 2222
ListenAddress 0.0.0.0
HostKey /data/ssh/ssh_host_ed25519_key
AuthorizedKeysFile /data/ssh/authorized_keys
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
AuthenticationMethods publickey
AllowUsers root
AllowTcpForwarding local
AllowStreamLocalForwarding local
GatewayPorts no
AllowAgentForwarding no
X11Forwarding no
PermitTunnel no
PermitUserEnvironment no
PidFile /run/codex-sshd.pid
Subsystem sftp internal-sftp
CONF
/usr/sbin/sshd -t -f /data/ssh/sshd_config
/usr/sbin/sshd -f /data/ssh/sshd_config
bashio::log.info "Key-only SSH ready on container port 2222; Herdr available"
}
