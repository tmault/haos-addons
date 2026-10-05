# Add-on flow tests

This repository uses [tester-army/e2e](https://github.com/tester-army/e2e),
with pinned `e2e` and `@e2e-dev/web` dependencies in `package-lock.json`.
The browser suites use deterministic locators and assertions, so they run
without a model subscription or API key. They drive actual upstream apps.

```bash
npm ci
npm run test:e2e:install
npm test
```

On Linux, install browser system libraries with
`npx @e2e-dev/web install chromium --with-deps` if needed.
`npm test` runs the host-safe script and Python regressions. The SSH suite
requires a disposable add-on container because it writes system paths;
the runner identifies this separately.

Select a single add-on to keep its tests and URL paired:

```bash
E2E_ADDON=dashy npm run test:e2e:list
E2E_ADDON=calibre npm run test:e2e:list
E2E_ADDON=codex-terminal npm run test:e2e:list
```

Run Dashy against an installed, built upstream checkout. The launcher creates
temporary configuration storage and runs the actual add-on entrypoint:

```bash
git init .e2e-runtime/dashy
git -C .e2e-runtime/dashy remote add origin https://github.com/Lissy93/dashy.git
git -C .e2e-runtime/dashy fetch --depth 1 origin 988b466dd585131096ae990aab4eb98175c5bd16
git -C .e2e-runtime/dashy checkout --detach FETCH_HEAD
npm --prefix .e2e-runtime/dashy install --no-audit --no-fund
npm --prefix .e2e-runtime/dashy run build
```

```bash
DASHY_SOURCE_DIR=.e2e-runtime/dashy npm run test:e2e:dashy
DASHY_SOURCE_DIR=.e2e-runtime/dashy npm run test:e2e:dashy-auth
```

Alternatively set `DASHY_URL` to a disposable instance seeded with the
configuration in `tests/e2e/dashy-server.sh`.
The separate authentication fixture runs on port 18081 with administrator and
reader test accounts; `DASHY_AUTH_URL` selects an equivalent existing instance.

Run Calibre against a disposable instance of the **built add-on image**:

```bash
CALIBRE_URL=http://127.0.0.1:18083 npm run test:e2e:calibre
```

With Docker available, let the runner build and start an isolated instance:

```bash
CALIBRE_DOCKER=1 npm run test:e2e:calibre
```

The launcher creates temporary Docker volumes, seeds the upstream empty
library, and removes its container and volumes on exit. With this launcher,
the book lifecycle test also restarts the container and checks that metadata
and shelf membership survive in those volumes. Leave `CALIBRE_DOCKER` unset
when using `CALIBRE_URL`; existing instances are not restarted.

The Calibre browser suite creates and changes library data. Its default
credentials are the upstream initial administrator credentials; override
`CALIBRE_USERNAME` and `CALIBRE_PASSWORD` for the disposable test instance.

Run Codex Terminal with `ttyd`, `tmux`, and Bash installed:

```bash
TTYD_BIN=/path/to/ttyd npm run test:e2e:codex
```

The launcher serves the real ttyd client and runs the actual session picker
with an isolated tmux socket. It substitutes the external Codex CLI with a
Bash process so terminal behavior can be verified without account credentials.
Set `CODEX_TERMINAL_URL` to use an existing equivalent disposable runtime.

Run the separate real SSH integration suite with Docker:

```bash
bash codex_terminal/tests/test-remote-access-container.sh
```

It builds the genuine add-on and runs key authentication, rejection, environment
and host-key persistence checks inside a disposable container.

Reports, JUnit XML, and Markdown summaries are written separately under
`.e2e/<add-on>/`. Failed attempts retain browser traces. Tests run serially
with zero retries, so a first failure remains visible. `npm` test scripts
disable e2e telemetry.

Passing these tests does not establish Home Assistant Supervisor installation,
ingress authentication, production account login, or upstream features absent
from the flow inventory.

| Add-on | Browser flows | Other integration coverage |
| --- | --- | --- |
| Dashy | Dashboard/search, tile/header navigation, Options theme/layout persistence, Minimal view, missing-route recovery, YAML save/reload, native admin/reader authentication, item/section/local-clock widget create/edit/delete and disk persistence | Startup seeding, existing config preservation, path overrides, process arguments and failure propagation |
| Calibre-Web Automated | Authentication/rejection/logout, category browsing, empty and populated search, profile/admin, shelf lifecycle, EPUB ingest/upload, metadata persistence, EPUB chapter reader, read/unread, archive/restore, shelf membership, download, EPUB-to-TXT conversion and deletion; authenticated OPDS catalog | Container restart and volume persistence with the isolated launcher; options/s6 environment mapping, zero trusted proxies, malformed and nonobject input, polling, service ordering |
| Codex Terminal | Picker choices, custom arguments, login dispatch, new/resume/reconnect sessions, shell commands, connection close/reopen, session replacement and invalid input | MCP discovery/fallback, EOF handling, scheduled/manual updates, package persistence and HA context generation; real SSH authentication/rejection/environment and persistent host keys in the built image |

The Codex tests verify the external CLI arguments, rather than logging into or
calling a paid model. MCP branch tests supply Supervisor responses and inspect
the resulting real setup commands. Browser and SSH tests use actual ttyd, tmux
and sshd. Supervisor installation and real HA authentication require an HAOS
test deployment and are outside the locally verified flows.

CI runs host regressions/type checking, each browser suite, and the isolated
SSH suite. Dashy source is pinned to a verified upstream revision; its upstream
dependency ranges and both add-ons' default `latest` base images can change.
Use the recorded verification versions when comparing failures. GitHub Actions
execution is separate from the local command results.

See [the local verification record](VERIFICATION.md) for final run counts,
versions and remaining validation.
