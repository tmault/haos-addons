import { test } from '@e2e-dev/web';
import { expect } from 'e2e';

const username = process.env.CALIBRE_USERNAME ?? 'admin';
const password = process.env.CALIBRE_PASSWORD ?? 'admin123';

test('Calibre rejects anonymous administration and invalid credentials', async ({ app, screen, browser }) => {
  await app.open('/admin/view');
  await expect(browser).toHaveURL(/\/login/);
  await expect(screen.getByLabel('Username')).toBeVisible();
  await screen.getByLabel('Username').fill(`nonexistent-e2e-${Date.now()}`);
  await screen.getByLabel('Password', { exact: true }).fill('invalid-e2e-password');
  await screen.getByRole('button', 'Login').tap();
  await expect(browser).toHaveURL(/\/login/);
  await expect(screen.getByText(/wrong username or password/i)).toBeVisible();
});

test('Calibre login, browse, search, profile, administration, shelf lifecycle and logout', async ({ app, screen, browser }) => {
  await app.open('/login');
  await screen.getByLabel('Username').fill(username);
  await screen.getByLabel('Password', { exact: true }).fill(password);
  await screen.getByRole('button', 'Login').tap();
  await expect(browser.locator('#top_admin')).toBeVisible();
  await expect(screen.getByLabel('Search')).toBeVisible();

  // These are real navigation surfaces, with assertions that reject a login
  // redirect, upstream traceback, or an error document with an HTTP 200 status.
  for (const path of ['/author', '/publisher', '/series', '/category', '/formats', '/language', '/ratings', '/table']) {
    const response = browser.waitForResponse(new RegExp(`${path}$`));
    await app.open(path);
    expect((await response).status).toBe(200);
    await expect(browser).toHaveURL(new RegExp(`${path}$`));
    await expect(browser.locator('#top_admin')).toBeVisible();
  }
  await screen.getByLabel('Search').fill('definitely-no-book-e2e-123456789');
  await screen.getByRole('button', 'Search', { exact: true }).tap();
  await expect(screen.getByText(/no results found/i)).toBeVisible();

  await app.open('/me');
  await expect(screen.getByLabel('Username')).toHaveValue(username);
  await expect(screen.getByLabel('Email', { exact: true })).toBeVisible();
  await app.open('/admin/view');
  await expect(screen.getByRole('heading', /Administration/)).toBeVisible();
  await app.open('/admin/dbconfig');
  await expect(screen.getByDisplayValue('/share/calibre-web-automated/library')).toBeVisible();

  const shelf = `E2E shelf ${Date.now()}`;
  await app.open('/shelf/create');
  await screen.getByLabel('Title').fill(shelf);
  await screen.getByRole('button', 'Save').tap();
  await screen.getByRole('link', new RegExp(shelf)).first().tap();
  await expect(browser.locator('h1, h2').filter({ hasText: shelf })).toBeVisible({ timeout: 30000 });
  await screen.getByRole('link', 'Edit Shelf Properties').tap();
  await screen.getByLabel('Title').fill(`${shelf} renamed`);
  await screen.getByRole('button', 'Save').tap();
  await screen.getByRole('link', new RegExp(`${shelf} renamed`)).first().tap();
  await expect(browser.locator('h1, h2').filter({ hasText: `${shelf} renamed` })).toBeVisible();
  await screen.getByText('Delete this Shelf').tap();
  await screen.getByRole('button', 'Delete', { exact: true }).tap();
  await expect(screen.getByRole('link', new RegExp(shelf))).toHaveCount(0);

  await browser.locator('.profileDrop').tap();
  await screen.getByRole('link', 'Logout').tap();
  await app.open('/admin/view');
  await expect(browser).toHaveURL(/\/login/);
  await expect(screen.getByLabel('Username')).toBeVisible();
});

test('Calibre uploads a real EPUB, persists metadata, shelves and downloads the book', { timeout: 360000 }, async ({ app, screen, browser }) => {
  await app.open('/login');
  await screen.getByLabel('Username').fill(username);
  await screen.getByLabel('Password', { exact: true }).fill(password);
  await screen.getByRole('button', 'Login').tap();
  await expect(browser.locator('#top_admin')).toBeVisible();

  const shelf = `E2E books ${Date.now()}`;
  await app.open('/shelf/create');
  await screen.getByLabel('Title').fill(shelf);
  await screen.getByRole('button', 'Save').tap();
  await app.open('/');
  const uploadedTitle = `HAOS E2E upload ${Date.now()}`;
  const { mkdtemp, rm } = await import('node:fs/promises');
  const { tmpdir } = await import('node:os');
  const { join } = await import('node:path');
  const { execFileSync } = await import('node:child_process');
  const fixtureDir = await mkdtemp(join(tmpdir(), 'haos-calibre-'));
  const fixture = join(fixtureDir, 'library.epub');
  execFileSync('python3', ['-c', `import sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as source, zipfile.ZipFile(sys.argv[2], 'w') as target:
 for entry in source.infolist():
  data = source.read(entry.filename)
  if entry.filename.endswith('.opf'): data = data.replace(b'HAOS E2E Library Book', sys.argv[3].encode())
  target.writestr(entry, data)`, 'tests/e2e/calibre-fixtures/library.epub', fixture, uploadedTitle]);
  // Upstream's file input has no accessible label.
  await browser.locator('#btn-upload').setInputFiles(fixture);
  await rm(fixtureDir, { recursive: true, force: true });
  // CWA uploads into its genuine ingest queue and opens Tasks.
  await expect(browser).toHaveURL(/\/tasks/);
  for (let attempt = 0; attempt < 45; attempt++) {
    await app.open('/');
    if (await screen.getByRole('link', uploadedTitle, { exact: true }).count()) break;
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  await screen.getByRole('link', uploadedTitle, { exact: true }).first().tap();
  await expect(screen.getByRole('heading', uploadedTitle).first()).toBeVisible();
  await expect(screen.getByRole('link', 'E2E Test Author').first()).toBeVisible();

  await screen.getByRole('button', 'Edit Metadata').tap();
  const title = `HAOS E2E edited ${Date.now()}`;
  await screen.getByLabel('Book Title', { exact: true }).fill(title);
  await browser.locator('#authors').fill('E2E Updated Author');
  await screen.getByLabel('Publisher', { exact: true }).fill('E2E Publisher');
  await screen.getByLabel('Tags', { exact: true }).fill('E2E Tag');
  await screen.getByRole('button', 'Save', { exact: true }).tap();
  await expect(screen.getByRole('heading', title).first()).toBeVisible();
  await expect(screen.getByRole('link', 'E2E Updated Author').first()).toBeVisible();
  await expect(screen.getByRole('link', 'E2E Publisher').first()).toBeVisible();
  await browser.reload();
  await expect(screen.getByRole('heading', title).first()).toBeVisible();

  const bookUrl = await browser.url();
  await screen.getByLabel('Search').fill(title);
  await screen.getByRole('button', 'Search', { exact: true }).tap();
  await expect(screen.getByRole('link', title, { exact: true }).first()).toBeVisible();
  await screen.getByRole('link', title, { exact: true }).first().tap();
  await expect(screen.getByRole('heading', title).first()).toBeVisible();

  // Reader is intentionally a new-tab link; open its actual destination in
  // this attempt and assert the EPUB chapter, rather than only reader chrome.
  await expect(screen.getByRole('button', 'Read in Browser', { exact: true })).toBeVisible();
  const readerLink = browser.locator('a[href^="/read/"][href$="/epub"]');
  await expect(readerLink).toBeVisible();
  const readerPath = await readerLink.getAttribute('href');
  expect(readerPath?.includes('/read/')).toBe(true);
  await app.open(readerPath!);
  await expect(browser.frameLocator('iframe').getByText('Original test content for upload and download verification.')).toBeVisible();
  await app.open(bookUrl);
  await screen.getByRole('button', 'Mark As Read', { exact: true }).tap();
  await browser.reload();
  await expect(screen.getByRole('button', 'Mark As Unread', { exact: true })).toBeVisible();
  await screen.getByRole('button', 'Mark As Unread', { exact: true }).tap();
  await browser.reload();
  await expect(screen.getByRole('button', 'Mark As Read', { exact: true })).toBeVisible();
  await screen.getByRole('button', 'Add to archive', { exact: true }).tap();
  await browser.reload();
  await expect(screen.getByRole('button', 'Restore from archive', { exact: true })).toBeVisible();
  await screen.getByRole('button', 'Restore from archive', { exact: true }).tap();
  await browser.reload();
  await expect(screen.getByRole('button', 'Add to archive', { exact: true })).toBeVisible();

  await screen.getByRole('button', 'Add to shelf', { exact: true }).tap();
  await screen.getByText(shelf, { exact: true }).tap();
  await browser.reload();
  await screen.getByRole('link', new RegExp(shelf)).first().tap();
  await expect(browser.locator('h1, h2').filter({ hasText: shelf })).toBeVisible({ timeout: 30000 });
  await screen.getByRole('link', title, { exact: true }).first().tap();
  await expect(screen.getByRole('heading', title).first()).toBeVisible();
  const download = await browser.waitForDownload(() => screen.getByRole('button', 'Download EPUB', { exact: true }).tap());
  expect(download.suggestedFilename.toLowerCase().endsWith('.epub')).toBe(true);
  const { readFile, readdir } = await import('node:fs/promises');
  // e2e returns an attempt-relative artifact reference, not a cwd path.
  const artifactRoot = '.e2e/calibre/artifacts';
  const downloadedArtifact = (await readdir(artifactRoot, { recursive: true })).find(path => path.endsWith(download.path));
  expect(Boolean(downloadedArtifact)).toBe(true);
  const bytes = await readFile(join(artifactRoot, downloadedArtifact!));
  expect(bytes.subarray(0, 2).toString()).toBe('PK');
  expect(bytes.length > 500).toBe(true);

  // Only the isolated launcher fixture authorizes restarting a container.
  if (process.env.CALIBRE_DOCKER === '1') {
    if (!app.baseUrl) throw new Error('Calibre fixture requires app.baseUrl');
    const state = JSON.parse(await readFile(`.e2e-runtime/calibre-${new URL(app.baseUrl!).port || '80'}.json`, 'utf8'));
    expect(typeof state.name === 'string' && /^haos-e2e-calibre-[0-9]+$/.test(state.name)).toBe(true);
    expect(new URL(state.url).origin).toBe(new URL(app.baseUrl!).origin);
    execFileSync(process.env.DOCKER_BIN ?? 'docker', ['restart', state.name], { timeout: 60000 });
    let ready = false;
    for (let attempt = 0; attempt < 60; attempt++) {
      try {
        ready = (await fetch(new URL('/login', app.baseUrl))).status === 200;
      } catch { /* Container startup has not bound the web port yet. */ }
      if (ready) break;
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    expect(ready).toBe(true);
    await app.open(bookUrl);
    // Session may survive restart; reauthenticate through the UI if needed.
    if (new URL(await browser.url()).pathname === '/login') {
      await screen.getByLabel('Username').fill(username);
      await screen.getByLabel('Password', { exact: true }).fill(password);
      await screen.getByRole('button', 'Login').tap();
      await app.open(bookUrl);
    }
    await expect(screen.getByRole('heading', title).first()).toBeVisible();
    await expect(screen.getByRole('link', 'E2E Updated Author').first()).toBeVisible();
    await screen.getByRole('link', new RegExp(shelf)).first().tap();
    await expect(screen.getByRole('link', title, { exact: true }).first()).toBeVisible();
    await screen.getByRole('link', title, { exact: true }).first().tap();
  }

  // Exercise the installed local Calibre converter and its actual output.
  await screen.getByRole('button', 'Edit Metadata').tap();
  await browser.locator('#book_format_from').selectOption('EPUB');
  await browser.locator('#book_format_to').selectOption('TXT');
  await screen.getByRole('button', 'Convert book', { exact: true }).tap();
  const bookId = new URL(bookUrl).pathname.split('/').pop();
  const cookie = (await browser.cookies()).map(item => `${item.name}=${item.value}`).join('; ');
  let convertedText = '';
  for (let attempt = 0; attempt < 45; attempt++) {
    const response = await fetch(new URL(`/download/${bookId}/txt/${bookId}.txt`, app.baseUrl), { headers: { Cookie: cookie } });
    if (response.status === 200 && response.headers.get('content-disposition')?.includes('attachment')) {
      convertedText = await response.text();
      break;
    }
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  expect(convertedText.includes('Original test content for upload and download verification.')).toBe(true);
  await app.open(bookUrl);

  await screen.getByRole('button', 'Delete Book', { exact: true }).tap();
  await screen.getByRole('button', 'Delete', { exact: true }).tap();
  await expect(screen.getByRole('link', title, { exact: true })).toHaveCount(0);
  await screen.getByRole('link', new RegExp(shelf)).first().tap();
  await expect(browser.locator('h1, h2').filter({ hasText: shelf })).toBeVisible({ timeout: 30000 });
  await expect(screen.getByRole('link', title, { exact: true })).toHaveCount(0);
  await screen.getByText('Delete this Shelf').tap();
  await screen.getByRole('button', 'Delete', { exact: true }).tap();
  await expect(screen.getByRole('link', new RegExp(shelf))).toHaveCount(0);
});

test('Calibre OPDS requires credentials and serves an authenticated Atom catalog', async ({ app }) => {
  const url = new URL('/opds', app.baseUrl);
  const anonymous = await fetch(url);
  expect(anonymous.status).toBe(401);
  const authenticated = await fetch(url, {
    headers: { Authorization: `Basic ${Buffer.from(`${username}:${password}`).toString('base64')}` },
  });
  expect(authenticated.status).toBe(200);
  expect(authenticated.headers.get('content-type')?.includes('application/atom+xml')).toBe(true);
  expect((await authenticated.text()).includes('http://www.w3.org/2005/Atom')).toBe(true);
});
