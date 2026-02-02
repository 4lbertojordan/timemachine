FROM debian:13.3-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    samba \
    samba-common-bin \
    smbclient \
    tini \
    iproute2 \
    tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/samba /var/run/samba /var/lib/samba

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 445

VOLUME ["/etc/samba", "/var/lib/samba", "/var/log/samba"]

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD smbstatus > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh", "/usr/bin/tini", "--"]

CMD ["smbd", "-F", "--no-process-group", "--debug-stdout"]