# PG Back Web for Railway. Pinned official image (version + multi-arch digest).
FROM eduardolat/pgbackweb:0.5.2@sha256:cd902026c133fbd8b25fd2a8b5b1727dbac94ae4094e12c0321442af449cac5c

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod +x /usr/local/bin/railway-start.sh

WORKDIR /app
EXPOSE 8085
CMD ["/usr/local/bin/railway-start.sh"]
