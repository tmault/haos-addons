# Local verification — 2026-10-04

Sol 6.1 implemented each add-on's tests and fixes. Luna 6 independently ran
the final browser suites against actual apps. All 23 browser tests passed
with zero retries and zero skips. Runs were serialized on the development host.

| Suite | Result | Final independent run ID |
| --- | --- | --- |
| Dashy core | 5 passed | `01a108c3-4f99-7379-8bc4-7c1e3da532c7` |
| Dashy native authentication | 2 passed | `01a108c3-a8c9-78f5-971d-6a5f609edcde` |
| Calibre-Web Automated | 4 passed | `01a108cd-bf57-7a45-910b-ddd6692f7b0e` |
| Codex Terminal | 12 passed | `01a108b8-ad98-7d74-9daf-2b15f25d96e5` |

The [flow inventory and reproduction commands](README.md) describe each suite.
Generated reports, traces and downloads live in ignored `.e2e/<add-on>/`
directories and are uploaded by the CI workflow.

Dashy used upstream 4.7.17 at commit
`988b466dd585131096ae990aab4eb98175c5bd16`, served through the actual add-on
entrypoint with temporary configuration. Persistence checks clear browser
storage before reloading saved configuration. Native reader restrictions
establish the UI behavior, not server-side RBAC.

Calibre used the actual wrapper image based on upstream v4.0.8
(`c873d206b9e1903d6d35b4e00f8de01c4dd159197e1f1218dac251a10c0e0f46`).
Its disposable container exercised real EPUB ingest, chapter reading,
metadata and shelf persistence, read/unread and archive/restore, EPUB download,
container restart, EPUB-to-TXT conversion with content verification, and
book/shelf deletion. Authentication, navigation and OPDS checks also passed.

Codex used ttyd 1.7.7 and real tmux with isolated sessions. The external Codex
CLI is substituted with a Bash process that reports its arguments; these tests
verify dispatch and terminal behavior without paid account access. Luna also
verified the genuine final-source add-on image `577c07dd0811` using the separate
SSH suite: disabled/no-key rejection, key permissions, authorized and rejected
keys, environment, Herdr 0.9.1, and stable host keys across an sshd restart.
That check did not restart the entire Codex container.

Final `npm test`, `npm run typecheck`, shell syntax checks for all 14 test
scripts, and `git diff --check` passed. Host regressions include seven Dashy
startup cases, nine Calibre options cases and six Codex script suites. The
container-only SSH tests ran separately from the host-safe test runner.

## Remaining validation

Live HAOS installation, Supervisor APIs and ingress authentication have not
been exercised. The Codex MCP and context regressions use recorded API doubles;
paid model execution and real account login remain unverified. External
identity providers, email, Kobo, Hardcover and other upstream integrations
outside the inventory have not been exercised.

GitHub Actions has not run on this change yet. The e2e dependencies are pinned;
Dashy's upstream dependency ranges and the add-ons' default `latest` image
references can drift. Compare failures with the versions recorded above.
