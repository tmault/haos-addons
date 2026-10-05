import type { E2EConfig } from 'e2e';
import { web } from '@e2e-dev/web';

// Select one add-on so its tests never run against another application's URL.
const addon = process.env.E2E_ADDON ?? 'dashy';
const definitions = {
  dashy: { url: process.env.DASHY_URL ?? 'http://127.0.0.1:18080', tests: 'tests/e2e/dashy.e2e.ts' },
  'dashy-auth': { url: process.env.DASHY_AUTH_URL ?? 'http://127.0.0.1:18081', tests: 'tests/e2e/dashy-auth.e2e.ts' },
  calibre: { url: process.env.CALIBRE_URL ?? `http://127.0.0.1:${process.env.CALIBRE_PORT ?? '18083'}`, tests: 'tests/e2e/calibre*.e2e.ts' },
  'codex-terminal': {
    url: process.env.CODEX_TERMINAL_URL ?? 'http://127.0.0.1:17681',
    tests: 'tests/e2e/codex*.e2e.ts',
  },
};
if (!Object.hasOwn(definitions, addon)) throw new Error(`Unknown E2E_ADDON ${addon}; choose ${Object.keys(definitions).join(', ')}`);
const selected = definitions[addon as keyof typeof definitions];

export default {
  projectId: 'haos-addons',
  tests: selected.tests,
  targets: [{
    name: addon,
    engine: web({ browser: 'chromium', viewport: { width: 1440, height: 1000 } }),
    app: {
      url: selected.url,
      ...(addon === 'calibre' && process.env.CALIBRE_DOCKER === '1' && !process.env.CALIBRE_URL ? {
        command: {
          executable: 'bash', args: ['tests/e2e/calibre-server.sh'],
          env: {
            DOCKER_BIN: process.env.DOCKER_BIN ?? 'docker',
            CALIBRE_NETWORK: process.env.CALIBRE_NETWORK ?? 'bridge',
            CALIBRE_PORT: process.env.CALIBRE_PORT ?? '18083',
            ...(process.env.DOCKER_BUILDKIT ? { DOCKER_BUILDKIT: process.env.DOCKER_BUILDKIT } : {}),
            ...(process.env.DOCKER_HOST ? { DOCKER_HOST: process.env.DOCKER_HOST } : {}),
          },
          startupTimeout: 600000,
          log: '.e2e/calibre-server.log',
        },
      } : {}),
      ...((addon === 'dashy' || addon === 'dashy-auth') && process.env.DASHY_SOURCE_DIR && !(addon === 'dashy' ? process.env.DASHY_URL : process.env.DASHY_AUTH_URL) ? {
        command: {
          executable: 'bash', args: [addon === 'dashy-auth' ? 'tests/e2e/dashy-auth-server.sh' : 'tests/e2e/dashy-server.sh'],
          env: { DASHY_SOURCE_DIR: process.env.DASHY_SOURCE_DIR },
          log: '.e2e/dashy-server.log',
        },
      } : {}),
      ...(addon === 'codex-terminal' && !process.env.CODEX_TERMINAL_URL ? {
        command: {
          executable: 'bash', args: ['tests/e2e/codex-server.sh'],
          env: { TTYD_BIN: process.env.TTYD_BIN ?? 'ttyd' },
          log: '.e2e/codex-server.log',
        },
      } : {}),
    },
  }],
  workers: 1,
  retries: 0,
  timeout: addon === 'calibre' ? 240000 : 120000,
  assertionTimeout: 10000,
  failOnSkippedFailure: true,
  trace: 'retain-on-failure',
  reporters: ['list', 'junit', 'markdown'],
  output: `.e2e/${addon}`,
} satisfies E2EConfig;
