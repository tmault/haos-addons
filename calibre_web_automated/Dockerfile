ARG CWA_IMAGE=crocodilestick/calibre-web-automated:latest
FROM ${CWA_IMAGE}

ENV PUID=1000 \
    PGID=1000 \
    TZ=Europe/Zurich \
    CWA_PORT_OVERRIDE=8083 \
    NETWORK_SHARE_MODE=false \
    TRUSTED_PROXY_COUNT=1 \
    DISABLE_LIBRARY_AUTOMOUNT=false

COPY rootfs /

RUN chmod 755 /etc/s6-overlay/s6-rc.d/ha-cwa-options/run \
    && grep -rlI -e '/calibre-library' -e '/cwa-book-ingest' /app/calibre-web-automated /etc/s6-overlay/s6-rc.d 2>/dev/null \
      | xargs -r sed -i \
        -e 's|/calibre-library|/share/calibre-web-automated/library|g' \
        -e 's|/cwa-book-ingest|/share/calibre-web-automated/ingest|g' \
    && python3 -c "import json; from pathlib import Path; path = Path('/app/calibre-web-automated/dirs.json'); data = json.loads(path.read_text()); data['ingest_folder'] = '/share/calibre-web-automated/ingest'; data['calibre_library_dir'] = '/share/calibre-web-automated/library'; path.write_text(json.dumps(data, indent=2) + '\n')"
