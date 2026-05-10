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

## Persistent Packages

Install packages that survive restarts:

```bash
persist-install apk vim htop
persist-install pip requests
persist-install list
```
