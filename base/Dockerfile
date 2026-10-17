# Binaries are downloaded by CI (gh release download) and copied from ./binaries/.
# Local builds: use build.sh (downloads binaries first) or place them manually in ./binaries/<arch>/.

FROM debian:bookworm-slim
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates curl sudo openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/local/bin/cc-proxy start -c /home/agent/.cc-proxy" >> /etc/sudoers.d/agent && \
    chmod 0440 /etc/sudoers.d/agent
COPY binaries/${TARGETARCH}/cc-proxy /usr/local/bin/cc-proxy
COPY binaries/${TARGETARCH}/multica /usr/local/bin/multica
COPY binaries/${TARGETARCH}/codex /usr/local/bin/codex
RUN chmod +x /usr/local/bin/cc-proxy /usr/local/bin/multica /usr/local/bin/codex
COPY base/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/agent/wiki /home/agent/.codex && \
    git config --system credential.helper store && \
    git config --system user.name agent && \
    git config --system user.email agent@container && \
    chown -R agent:agent /home/agent
WORKDIR /home/agent
ENTRYPOINT ["/entrypoint.sh"]
