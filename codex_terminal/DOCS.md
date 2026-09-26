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

## Herdr and SSH

Herdr 0.9.1 is included. To enable remote access, set `ssh_enabled: true`
and add one or more OpenSSH public keys to `ssh_authorized_keys`. Password
login is disabled. The SSH server listens on container port 2222, which is
unmapped by default. SSH host keys persist under `/data/ssh`.

For private tailnet access, forward a Tailscale Serve TCP port to the app's
internal IP on port 2222 and leave the add-on host port unmapped. For example,
run in the Tailscale app, substituting the internal Codex Terminal IP:

```sh
/opt/tailscale serve --bg --tcp=2222 tcp://<app-internal-IP>:2222
```

Connect as `root` with the private key matching an authorized public key.
Add the SSH target with `herdr machine add <ssh-alias> --label "Home Assistant Codex"`.
Remote shells use `/data/home`, `/data/.codex`, and the same Home Assistant
context as the web terminal. In a Herdr pane, `tmux new-session -A -s codex codex-ha`
attaches to the shared Codex terminal session (or starts it if absent).

SSH permits local TCP and Unix-socket forwarding for Herdr. Agent forwarding,
password authentication, remote TCP forwarding, and tunnels are disabled.
Disabling `ssh_enabled` takes effect when the app restarts. Rebuilding or restarting
the app interrupts active terminals; persisted Codex history and credentials remain.
