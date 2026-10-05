#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for script in codex_terminal/tests/test-*.sh dashy_latest/tests/test-*.sh; do
  [[ -f "$script" ]] || continue
  if [[ "$script" == 'codex_terminal/tests/test-remote-access.sh' || "$script" == *-container.sh ]]; then
    printf 'Container-only suite: %s (run separately in a disposable add-on image)\n' "$script"
    continue
  fi
  printf '\nRunning %s\n' "$script"
  bash "$script"
done
python3 -m unittest discover -s calibre_web_automated/tests -v
