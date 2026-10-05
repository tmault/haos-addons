import { test, type Browser } from '@e2e-dev/web';
import { expect } from 'e2e';

// The actual ttyd client renders output; no synthetic terminal DOM is served.
const text = (browser: Browser) => browser.evaluate(() => {
  const terminal = (window as any).term;
  if (!terminal) return document.body.innerText;
  const buffer = terminal.buffer.active;
  return Array.from({ length: buffer.length }, (_, i) => buffer.getLine(i)?.translateToString(true) ?? '').join('\n');
});

for (const [choice, args] of [['1', ''], ['2', 'resume --last'], ['3', 'resume'], ['5', 'login'], ['', '']]) {
  test(`Codex picker option ${choice} launches ${args || 'interactive session'}`, async ({ app, browser }) => {
    await app.open();
    await expect.poll(() => text(browser)).toContain('Enter your choice');
    await browser.keyboard.type(choice);
    await browser.keyboard.press('Enter');
    await expect.poll(() => text(browser)).toContain(`CODEX_TEST_ARGS:${args}`);
    await browser.keyboard.type("printf 'ACTIVE_%s\\n' session");
    await browser.keyboard.press('Enter');
    await expect.poll(() => text(browser)).toContain('ACTIVE_session');
    // Terminate only this isolated tmux session so subsequent tests start clean.
    await browser.keyboard.type('exit');
    await browser.keyboard.press('Enter');
  });
}

test('Codex shell accepts commands and reconnect preserves tmux state', async ({ app, browser }) => {
  await browser.onDialog('accept');
  await app.open();
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('1');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('CODEX_TEST_ARGS:');
  await browser.keyboard.type('export CODEX_FLOW_TOKEN=survives-reconnect');
  await browser.keyboard.press('Enter');
  await browser.keyboard.type(`printf 'READY_%s\\n' "$CODEX_FLOW_TOKEN"`);
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('READY_survives-reconnect');
  await browser.reload();
  await expect.poll(() => text(browser)).toContain('Reconnect to existing session');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('READY_survives-reconnect');
  await browser.keyboard.type(`printf 'AFTER_%s\\n' "$CODEX_FLOW_TOKEN"`);
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('AFTER_survives-reconnect');
  await browser.keyboard.type('exit');
  await browser.keyboard.press('Enter');
});

for (const [args, expected] of [['exec "summarize config"', 'exec summarize config'], ['', '']]) {
  test(`Codex custom command ${args || 'blank defaults to interactive'}`, async ({ app, browser }) => {
    await app.open();
    await expect.poll(() => text(browser)).toContain('Enter your choice');
    await browser.keyboard.type('4');
    await browser.keyboard.press('Enter');
    await expect.poll(() => text(browser)).toContain('> codex-ha');
    await browser.keyboard.type(args);
    await browser.keyboard.press('Enter');
    await expect.poll(() => text(browser)).toContain(`CODEX_TEST_ARGS:${expected}`);
    await browser.keyboard.type('exit');
    await browser.keyboard.press('Enter');
  });
}

test('Codex new session replaces the existing session after reload', async ({ app, browser }) => {
  await browser.onDialog('accept');
  await app.open();
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('1');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('CODEX_TEST_ARGS:');
  await browser.keyboard.type('export CODEX_OLD_SESSION=old-session');
  await browser.keyboard.press('Enter');
  await browser.keyboard.type("printf 'OLD_%s\\n' set");
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('OLD_set');
  await browser.reload();
  await expect.poll(() => text(browser)).toContain('Reconnect to existing session');
  await browser.keyboard.type('1');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('CODEX_TEST_ARGS:');
  await browser.keyboard.type(`printf 'NEW_%s\\n' "\${CODEX_OLD_SESSION:-clean}"`);
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('NEW_clean');
  await browser.keyboard.type('exit');
  await browser.keyboard.press('Enter');
});

test('Codex reconnect choice without a session returns to picker', async ({ app, browser }) => {
  await app.open();
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('0');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('No existing session found');
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('6');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('Dropping to bash shell');
  await browser.keyboard.type("printf 'RECOVERED_%s\\n' shell");
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('RECOVERED_shell');
  await browser.keyboard.type('exit');
  await browser.keyboard.press('Enter');
});

test('Codex exit closes the ttyd connection and can reopen', async ({ app, browser }) => {
  await app.open();
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('7');
  await browser.keyboard.press('Enter');
  await expect.poll(() => browser.evaluate(() => document.body.innerText)).toContain('Reconnect');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('7');
  await browser.keyboard.press('Enter');
});

test('Codex picker rejects invalid choices then opens the real Bash shell', async ({ app, browser }) => {
  await app.open();
  await expect.poll(() => text(browser)).toContain('Enter your choice');
  await browser.keyboard.type('9');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('Invalid choice: 9');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('Choose your Codex session type');
  await browser.keyboard.type('6');
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('Dropping to bash shell');
  await browser.keyboard.type("printf 'REAL_%s\\n' bash");
  await browser.keyboard.press('Enter');
  await expect.poll(() => text(browser)).toContain('REAL_bash');
  await browser.keyboard.type('exit');
  await browser.keyboard.press('Enter');
});
