# Stage 1: download cc-proxy (gnu binary, runs on debian-slim)
FROM debian:bookworm-slim AS cc-proxy-downloader
ARG CC_PROXY_VERSION
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /out && \
    curl -fsSL -o /out/cc-proxy "https://github.com/courage-zen/cc-proxy/releases/download/v${CC_PROXY_VERSION}/cc-proxy-${TARGETARCH}" && \
    chmod +x /out/cc-proxy

# Stage 2: download multica (static Go binary)
FROM debian:bookworm-slim AS multica-downloader
ARG MULTICA_VERSION
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /out && \
    curl -L -o /out/multica.tar.gz "https://github.com/multica-ai/multica/releases/download/v${MULTICA_VERSION}/multica-cli-${MULTICA_VERSION}-linux-${TARGETARCH}.tar.gz" && \
    tar -xzf /out/multica.tar.gz -C /out && \
    chmod +x /out/multica && \
    rm /out/multica.tar.gz

# Stage 3: download codex (musl static binary)
FROM debian:bookworm-slim AS codex-downloader
ARG CODEX_VERSION
ARG TARGETARCH
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /out && \
    case "${TARGETARCH}" in \
    amd64) CODEX_ARCH="x86_64" ;; \
    arm64) CODEX_ARCH="aarch64" ;; \
    *)     CODEX_ARCH="x86_64" ;; \
    esac && \
    curl -fsSL -o /out/codex.tar.gz "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-${CODEX_ARCH}-unknown-linux-musl.tar.gz" && \
    tar -xzf /out/codex.tar.gz -C /out && \
    mv "/out/codex-${CODEX_ARCH}-unknown-linux-musl" /out/codex && \
    chmod +x /out/codex && \
    rm /out/codex.tar.gz

# Stage 4: final image
FROM debian:bookworm-slim
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates curl sudo openssh-client && \
    rm -rf /var/lib/apt/lists/* && \
    useradd -m -s /bin/bash agent && \
    echo "agent ALL=(ALL) NOPASSWD: /usr/local/bin/cc-proxy start -c /home/agent/.cc-proxy" >> /etc/sudoers.d/agent && \
    chmod 0440 /etc/sudoers.d/agent
COPY --from=cc-proxy-downloader /out/cc-proxy /usr/local/bin/cc-proxy
COPY --from=multica-downloader /out/multica /usr/local/bin/multica
COPY --from=codex-downloader /out/codex /usr/local/bin/codex
COPY base/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /home/agent/wiki /home/agent/.codex && \
    git config --system credential.helper store && \
    git config --system user.name agent && \
    git config --system user.email agent@container && \
    chown -R agent:agent /home/agent
WORKDIR /home/agent
ENTRYPOINT ["/entrypoint.sh"]
