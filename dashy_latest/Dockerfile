ARG DASHY_IMAGE=lissy93/dashy:latest
FROM ${DASHY_IMAGE}

USER root

ENV USER_DATA_DIR=../config \
    IS_DOCKER=true \
    PORT=8080 \
    HOST=0.0.0.0

COPY rootfs /
RUN chmod 755 /usr/local/bin/ha-dashy-entrypoint

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/ha-dashy-entrypoint"]
CMD ["node", "server.js"]
