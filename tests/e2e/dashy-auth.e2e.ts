import { test } from '@e2e-dev/web';
import { expect } from 'e2e';

// Public throwaway fixture accounts, never production credentials.
test('Dashy rejects invalid credentials; admin login, reload and logout work', async ({ app, screen, browser }) => {
  await app.open('/');
  await expect(browser).toHaveURL(/\/login$/);
  await expect(screen.getByRole('button', 'Continue as Guest')).toHaveCount(0);
  // Upstream input labels lack associated IDs, so use owning form classes.
  await browser.locator('.username input').fill('e2e-admin');
  await browser.locator('.password input').fill('wrong-password');
  await screen.getByRole('button', 'Login', { exact: true }).tap();
  await expect(screen.getByText('Incorrect Password', { exact: true })).toBeVisible();
  await expect(browser).toHaveURL(/\/login$/);
  await browser.locator('.password input').fill('12345');
  await screen.getByRole('button', 'Login', { exact: true }).tap();
  await expect(screen.getByRole('heading', 'HAOS Dashy E2E')).toBeVisible();
  await expect(screen.getByRole('link', /^Configuration file/)).toBeVisible();
  await browser.reload();
  await expect(screen.getByRole('link', /^Configuration file/)).toBeVisible();
  await screen.getByRole('button', 'Options', { exact: true }).tap();
  await expect(screen.getByRole('button', 'Config', { exact: true })).toBeVisible();
  await expect(screen.getByRole('button', 'Edit Mode', { exact: true })).toBeVisible();
  await screen.getByRole('button', 'Sign Out', { exact: true }).tap();
  await expect(browser).toHaveURL(/\/login$/);
  await expect(browser.locator('.username input')).toBeVisible();
  await app.open('/');
  await expect(browser).toHaveURL(/\/login$/);
});

test('Dashy normal user can read dashboard but cannot open configuration or edit mode', async ({ app, screen, browser }) => {
  await app.open('/');
  await browser.locator('.username input').fill('e2e-reader');
  await browser.locator('.password input').fill('12345');
  await screen.getByRole('button', 'Login', { exact: true }).tap();
  await expect(screen.getByRole('link', /^Configuration file/)).toBeVisible();
  await screen.getByRole('button', 'Options', { exact: true }).tap();
  await expect(screen.getByRole('button', 'Config', { exact: true })).toHaveCount(0);
  await expect(screen.getByRole('button', 'Edit Mode', { exact: true })).toHaveCount(0);
  await browser.reload();
  await expect(screen.getByRole('link', /^Configuration file/)).toBeVisible();
  await screen.getByRole('button', 'Options', { exact: true }).tap();
  await expect(screen.getByRole('button', 'Config', { exact: true })).toHaveCount(0);
  await screen.getByRole('button', 'Sign Out', { exact: true }).tap();
  await expect(browser).toHaveURL(/\/login$/);
});
