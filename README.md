# Tom's HAOS Add-ons

A small Home Assistant OS add-ons repository.

## Add-ons

| Add-on | Description |
| --- | --- |
| Calibre-Web Automated | Runs Calibre-Web Automated from the current public Docker image, with library and ingest folders in `/share/calibre-web-automated`. |
| Dashy Latest | Runs Dashy from the current public `lissy93/dashy:latest` Docker image. |
| Codex Terminal | Runs OpenAI Codex CLI in a Home Assistant ingress terminal with generated HA context and `ha_mcp` integration. |

## Installation

Add this repository to the Home Assistant add-on store:

```text
https://github.com/tmault/haos-addons
```

Then install the add-on you want from the store.

## Structure

This repository follows the common Home Assistant add-ons repository layout:

```text
repository.json
calibre_web_automated/
  config.yaml
  Dockerfile
  CHANGELOG.md
  rootfs/
dashy_latest/
  config.yaml
  Dockerfile
  CHANGELOG.md
  icon.png
  rootfs/
codex_terminal/
  config.yaml
  build.yaml
  Dockerfile
  DOCS.md
  CHANGELOG.md
  scripts/
```

Each top-level add-on folder contains its own Home Assistant `config.yaml` and
runtime files.

## Credits

The Dashy add-on here was inspired by Benoit Anastay's Home Assistant add-ons
repository and Dashy add-on work:

- https://github.com/BenoitAnastay/home-assistant-addons-repository
- https://github.com/BenoitAnastay/dashy-home-assistant-addon

Dashy itself is created and maintained upstream by Alicia Sykes:

- https://github.com/Lissy93/dashy
- https://dashy.to/

Codex Terminal uses OpenAI Codex CLI and links to Home Assistant MCP Server:

- https://github.com/openai/codex
- https://github.com/homeassistant-ai/ha-mcp

The Codex Terminal app was patterned after Claude Terminal for Home Assistant:

- https://github.com/heytcass/home-assistant-addons/tree/main/claude-terminal
