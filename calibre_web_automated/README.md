# Calibre-Web Automated

Runs [Calibre-Web Automated](https://github.com/crocodilestick/Calibre-Web-Automated)
inside Home Assistant OS.

This wrapper uses the upstream `crocodilestick/calibre-web-automated:latest`
image and adapts its storage paths for Home Assistant:

- App config is stored in the add-on config directory at `/config`.
- The Calibre library is stored in `/share/calibre-web-automated/library`.
- The ingest folder is stored in `/share/calibre-web-automated/ingest`.

Files placed in the ingest folder are processed by CWA and removed after
import. Download files somewhere else first, then move completed files into the
ingest folder.

## First Start

After installing and starting the add-on, open the web UI on port `8083`.

Default upstream login:

- Username: `admin`
- Password: `admin123`

Change the default password immediately after first login.

## Options

- `timezone`: Time zone passed to CWA. Default: `Europe/Zurich`.
- `network_share_mode`: Enable this if your `/share` storage is backed by
  NFS, SMB, unionfs, or mergerfs.
- `force_polling`: Force polling-based watchers instead of inotify.
- `trusted_proxy_count`: Number of reverse proxies in front of CWA.
- `hardcover_token`: Optional Hardcover API token for metadata features.
- `disable_library_automount`: Skip CWA's automatic library detection/mount.

## Paths

On HAOS, use these host paths:

```text
/share/calibre-web-automated/library
/share/calibre-web-automated/ingest
/share/calibre-web-automated/plugins
```

For an existing Calibre library, stop the add-on, copy the library folder
containing `metadata.db` into `/share/calibre-web-automated/library`, then start
the add-on again.
