# Codex Terminal verification

From the repository root:

```sh
bash codex_terminal/tests/test-session-picker.sh
bash codex_terminal/tests/test-ha-mcp.sh
bash codex_terminal/tests/test-ha-context.sh
bash codex_terminal/tests/test-persist-install.sh
bash codex_terminal/tests/test-codex-update.sh
bash codex_terminal/tests/test-codex-update-scheduler.sh
E2E_ADDON=codex-terminal TTYD_BIN=ttyd npm run test:e2e
bash codex_terminal/tests/test-remote-access-container.sh
```

The browser suite runs the real ttyd client, tmux, session picker and Bash. It
covers each menu choice, defaults, custom arguments, invalid input, terminal
commands, reconnect persistence, session replacement and exit/reopen. Only
`codex`/`codex-ha` are substituted with an argument-reporting Bash process: paid
model execution, upstream login and the real Codex resume UI require an
authenticated live environment and are not verified by these tests.

Host MCP tests use the production setup script and real jq with simulated
Supervisor responses and Codex CLI. They cover internal container DNS/port,
fallbacks, disabled/missing-token behavior and endpoint secret redaction. They
do not establish access to a live Home Assistant instance.

Context tests run the real generator/jq against deterministic Supervisor responses
and cover summary/full output, partial/malformed/unavailable APIs, omission of
uninstalled apps and secrets, and prerequisite failure preserving the old file.
Persistence tests use a temporary `PERSIST_INSTALL_CONFIG_FILE`, real jq and
recording package managers to verify saved APK/pip lists, deduplication, listing
and rejected input. They do not download packages or restart a live add-on.

The container harness builds the production Dockerfile and runs actual sshd and
SSH clients. It checks disabled SSH, rejection without authorized keys, valid
and invalid keys, remote persistent environment, Herdr availability, permissions,
sshd authentication/forwarding policy and stable host keys after sshd restart.
All writable files remain in the disposable container; it publishes no ports.
Docker, registry access and package download access are required.

Override `DOCKER_BIN`, `DOCKER_HOST`, `BUILD_ARCH`, `BUILD_FROM` or
`CODEX_REMOTE_TEST_IMAGE` when needed. `CODEX_TEST_BUILD_NETWORK=host` is useful
with a temporary Docker daemon that has no bridge networking; it affects the
build only. These tests do not verify Supervisor ingress or a complete HAOS
installation.
