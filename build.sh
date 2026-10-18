#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ARCH="${1:-amd64}"
VARIANT="${2:-base}"

# Docker daemon pre-check
docker info > /dev/null 2>&1 || { echo "Error: Docker is not available or daemon is not running" >&2; exit 1; }

# Validate ARCH
if [ "$ARCH" != "amd64" ] && [ "$ARCH" != "arm64" ]; then
    echo "Error: ARCH must be 'amd64' or 'arm64'" >&2
    exit 1
fi

# Validate VARIANT
if [ "$VARIANT" != "base" ]; then
    echo "Error: VARIANT must be 'base'" >&2
    exit 1
fi

# Validate versions.yaml exists
if [ ! -f "${SCRIPT_DIR}/versions.yaml" ]; then
    echo "Error: versions.yaml not found: ${SCRIPT_DIR}/versions.yaml" >&2
    exit 1
fi

# Read versions from YAML
PROJECT_VERSION=$(python3 -c "import yaml; print(yaml.safe_load(open('${SCRIPT_DIR}/versions.yaml'))['project']['version'])" 2>&1) || {
    echo "Error: failed to read project version" >&2; exit 1
}
MULTICA_VERSION=$(python3 -c "import yaml; print(yaml.safe_load(open('${SCRIPT_DIR}/versions.yaml'))['multica']['version'])" 2>&1) || {
    echo "Error: failed to read multica version" >&2; exit 1
}
CODEX_VERSION=$(python3 -c "import yaml; print(yaml.safe_load(open('${SCRIPT_DIR}/versions.yaml'))['codex']['version'])" 2>&1) || {
    echo "Error: failed to read codex version" >&2; exit 1
}
CC_PROXY_VERSION=$(python3 -c "import yaml; print(yaml.safe_load(open('${SCRIPT_DIR}/versions.yaml'))['cc_proxy']['version'])" 2>&1) || {
    echo "Error: failed to read cc-proxy version" >&2; exit 1
}

case "${ARCH}" in
    amd64) CODEX_ARCH="x86_64" ;;
    arm64) CODEX_ARCH="aarch64" ;;
esac

# Download binaries (cc-proxy is private: requires locally authenticated gh
# with access to courage-zen/cc-proxy; CI uses the CC_PROXY_TOKEN secret)
echo "Downloading binaries to binaries/${ARCH}/ ..."
mkdir -p "${SCRIPT_DIR}/binaries/${ARCH}"

gh release download "v${MULTICA_VERSION}" -R multica-ai/multica -p "multica-cli-*-linux-${ARCH}.tar.gz" -O "/tmp/multica.tar.gz" --clobber
tar -xzf /tmp/multica.tar.gz -C "binaries/${ARCH}" multica
rm /tmp/multica.tar.gz

gh release download "rust-v${CODEX_VERSION}" -R openai/codex -p "codex-${CODEX_ARCH}-unknown-linux-musl.tar.gz" -O "/tmp/codex.tar.gz" --clobber
tar -xzf /tmp/codex.tar.gz -C "binaries/${ARCH}" "codex-${CODEX_ARCH}-unknown-linux-musl"
mv "binaries/${ARCH}/codex-${CODEX_ARCH}-unknown-linux-musl" "binaries/${ARCH}/codex"
rm /tmp/codex.tar.gz

gh release download "v${CC_PROXY_VERSION}" -R courage-zen/cc-proxy -p "cc-proxy-${ARCH}" -O "binaries/${ARCH}/cc-proxy" --clobber

chmod +x "binaries/${ARCH}/"*

DOCKERFILE="${SCRIPT_DIR}/base/Dockerfile"
TAG="codex-with-multica:${PROJECT_VERSION}-${ARCH}"

echo "Building: TAG=${TAG}"
echo "  PROJECT_VERSION=${PROJECT_VERSION}"
echo "  MULTICA_VERSION=${MULTICA_VERSION}"
echo "  CODEX_VERSION=${CODEX_VERSION}"
echo "  CC_PROXY_VERSION=${CC_PROXY_VERSION}"

docker build --progress=plain -f "${DOCKERFILE}" \
    --build-arg "TARGETARCH=${ARCH}" \
    -t "${TAG}" "${SCRIPT_DIR}" || {
    echo "Error: docker build failed for ${TAG}" >&2; exit 1
}
