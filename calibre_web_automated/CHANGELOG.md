# Changelog

## Unreleased

- Preserve a configured trusted proxy count of zero.
- Fall back safely when options JSON is not an object.
- Add startup option regressions and real library browser flow tests.

## 4.0.7

- Avoid recursively changing ownership of CWA application files during add-on startup.

## 4.0.6

- Initial Home Assistant wrapper around `crocodilestick/calibre-web-automated:latest`.
- Store the CWA library and ingest folders under `/share/calibre-web-automated`.
