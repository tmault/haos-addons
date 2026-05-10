# Codex Terminal Documentation

## First Run

Open Codex Terminal from the Home Assistant sidebar or the app page. The app starts a persistent `tmux` session and runs Codex in `/config`:

```bash
codex --cd /config --sandbox workspace-write --ask-for-approval on-request
```

If Codex is not authenticated, run:

```bash
codex login
```

## Terminal History

The browser terminal keeps extended xterm scrollback and the tmux session keeps pane history. Scroll in the terminal viewport to review earlier output on desktop or mobile.

## Home Assistant Context

Startup generates `/data/home/AGENTS.md` and configures Codex to load it with `model_instructions_file`. Refresh it manually with:

```bash
ha-context
ha-context --full
```

## Home Assistant MCP

Startup configures a Codex MCP server named `home-assistant`.

The preferred connection uses the installed Home Assistant MCP Server app (`ha_mcp`). If that app is not installed or not running, Codex Terminal falls back to running `ha-mcp` through `uvx`.

Check the configured MCP server with:

```bash
codex mcp list
```

## Codex CLI Updates

The add-on image installs the latest available `@openai/codex` package when the image is built. Update the CLI from an active terminal with:

```bash
codex-update
```

The update applies to new Codex processes. Restart Codex or open a new terminal session after the command finishes.

Install a specific version or clear the saved startup pin with:

```bash
codex-update 0.130.0
codex-update --clear-pin
```

Scheduled updates are controlled by the add-on configuration:

```yaml
codex_auto_update: true
codex_auto_update_time: "03:30"
codex_auto_update_days: daily
```

`codex_auto_update_days` accepts `daily`, `weekdays`, `weekends`, or comma-separated days such as `mon,wed,fri`.

## Persistent Packages

Install packages that survive restarts:

```bash
persist-install apk vim htop
persist-install pip requests
persist-install list
```
