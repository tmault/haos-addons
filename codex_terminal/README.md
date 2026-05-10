# Codex Terminal

Codex Terminal runs the OpenAI Codex CLI inside Home Assistant with a browser terminal, persistent Codex auth, generated Home Assistant context, and MCP access through `ha_mcp`.

## Features

- Web terminal through Home Assistant ingress.
- Codex CLI installed from `@openai/codex`.
- Persistent Codex auth and config under `/data/.codex`.
- Starts in `/config` so Codex can inspect and edit Home Assistant config.
- Generates `/data/home/AGENTS.md` with Home Assistant system context and configures Codex to load it.
- Registers a Codex MCP server named `home-assistant`.
- Prefers the installed Home Assistant MCP Server app endpoint and falls back to `uvx ha-mcp`.
- Keeps terminal history scrollable in the browser with tmux mouse scrolling and extended xterm scrollback.
- Optional persistent APK and pip package installation.

## Configuration

| Option | Default | Description |
| --- | --- | --- |
| `auto_launch_codex` | `true` | Start Codex automatically when the terminal opens. |
| `ha_smart_context` | `true` | Generate Home Assistant context for Codex sessions. |
| `enable_ha_mcp` | `true` | Configure the `home-assistant` MCP server for Codex. |
| `prefer_ha_mcp_app` | `true` | Use the installed `ha_mcp` app HTTP endpoint before trying the local stdio fallback. |
| `codex_auto_update` | `true` | Run scheduled Codex CLI updates in the background. |
| `codex_auto_update_time` | `03:30` | Local `HH:MM` time for scheduled Codex CLI updates. |
| `codex_auto_update_days` | `daily` | `daily`, `weekdays`, `weekends`, or comma-separated days such as `mon,wed,fri`. |
| `persistent_apk_packages` | `[]` | APK packages to install on startup. |
| `persistent_pip_packages` | `[]` | pip packages to install on startup. |

## Usage

Open the web UI from Home Assistant. By default the terminal attaches to a persistent `tmux` session and runs:

```bash
codex --cd /config --sandbox workspace-write --ask-for-approval on-request
```

Run `codex login` in the terminal if Codex is not authenticated yet.

Scroll up in the web terminal to review previous Codex output. The add-on keeps a large browser-side scrollback buffer and enables tmux mouse scrolling so desktop trackpads, mouse wheels, and mobile scroll gestures can reach older pane history.

Useful commands:

```bash
codex-ha
codex mcp list
ha-context
ha-context --full
codex-update
codex-update 0.130.0
codex-update --clear-pin
persist-install apk vim htop
persist-install pip requests
```

## Codex CLI Updates

The image installs `@openai/codex@latest` when the add-on image is built. To update Codex CLI inside a running terminal session, run:

```bash
codex-update
```

The command resolves the current npm `latest` version, installs that exact version globally, and saves it to `/data/codex-cli-version` so the add-on can restore the same CLI version on future starts. Restart Codex or open a new terminal session after updating; an already-running Codex process keeps using the version it started with.

Use `codex-update 0.130.0` to install a specific version, `codex-update --no-persist` for a one-off update, or `codex-update --clear-pin` to return future starts to the version baked into the add-on image.

When `codex_auto_update` is enabled, the add-on runs `codex-update latest` at `codex_auto_update_time` on `codex_auto_update_days`. Scheduled update logs are written to `/data/codex-update-scheduler.log`.

## MCP

When `enable_ha_mcp` is enabled, startup removes any existing `home-assistant` MCP entry and recreates it.

The preferred path uses the installed Home Assistant MCP Server app. The app's secret URL is read from the Supervisor API and stored in Codex config without printing the secret path to logs.

If the `ha_mcp` app is unavailable, Codex Terminal falls back to:

```bash
codex mcp add home-assistant \
  --env HOMEASSISTANT_URL=http://supervisor/core \
  --env HOMEASSISTANT_TOKEN=$SUPERVISOR_TOKEN \
  -- uvx --index-strategy unsafe-best-match ha-mcp@3.5.1
```

## Upstream

- Codex CLI: https://github.com/openai/codex
- Home Assistant MCP Server: https://github.com/homeassistant-ai/ha-mcp
- Inspired by Claude Terminal for Home Assistant: https://github.com/heytcass/home-assistant-addons/tree/main/claude-terminal
