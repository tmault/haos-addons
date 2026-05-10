# Tom's HAOS Add-ons

A small Home Assistant OS add-ons repository.

## Add-ons

| Add-on | Description |
| --- | --- |
| Calibre-Web Automated | Runs Calibre-Web Automated from the current public Docker image, with library and ingest folders in `/share/calibre-web-automated`. |
| Dashy Latest | Runs Dashy from the current public `lissy93/dashy:latest` Docker image. |

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
