# Changelog

## Unreleased

- Exit the session picker when terminal input closes.
- Use the MCP container port with internal add-on DNS, regardless of the published host port.
- Install the SSH client for outgoing SSH and Git connections.
- Preserve valid package configuration when adding persistent packages.
- Generate Home Assistant context when optional fields or API responses are unavailable.
- Add real terminal browser tests, MCP/EOF regressions, and a disposable SSH integration harness.

## 0.1.4

- Pass `--no-daemon` when launching new or resumed Codex sessions to fix startup failures inside Home Assistant OS.

## 0.1.3

- Add optional public-key-only SSH access and pinned, checksum-verified Herdr 0.9.1.
- Persist SSH host keys and share the web terminal Codex environment with remote sessions.
- Keep SSH disabled and its host port unmapped by default.

## 0.1.2

- Add configurable scheduled Codex CLI updates.
- Support daily, weekday, weekend, or explicit day schedules.
- Install system Bubblewrap so Codex can use the OS sandbox helper without startup warnings.

## 0.1.1

- Install the latest Codex CLI package when building the add-on image.
- Add `codex-update` for user-initiated Codex CLI updates from an active terminal.
- Restore a user-pinned Codex CLI version on future add-on starts.
- Enable scrollback in the web terminal with extended ttyd/xterm history and tmux mouse scrolling.

## 0.1.0

- Initial Codex Terminal app.
- Adds OpenAI Codex CLI, ingress terminal, persistent auth, generated Home Assistant context, and ha_mcp integration.
