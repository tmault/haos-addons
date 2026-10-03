# Changelog

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
