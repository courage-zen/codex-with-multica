# Binaries are downloaded by CI (gh release download) and copied from ./binaries/.
# Local builds: use build.sh (downloads binaries first) or place them manually in ./binaries/<arch>/.
#
# NOTE: cc-proxy is temporarily excluded (repo is private). Will be re-added
# when cc-proxy publishes its Codex-capable release.

FROM debian:bookworm-slim
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates curl openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash agent
COPY binaries/${TARGETARCH}/multica /usr/local/bin/multica
COPY binaries/${TARGETARCH}/codex /usr/local/bin/codex
RUN chmod +x /usr/local/bin/multica /usr/local/bin/codex
COPY base/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/agent/wiki /home/agent/.codex && \
    git config --system credential.helper store && \
    git config --system user.name agent && \
    git config --system user.email agent@container && \
    chown -R agent:agent /home/agent
WORKDIR /home/agent
ENTRYPOINT ["/entrypoint.sh"]
