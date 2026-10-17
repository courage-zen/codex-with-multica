#!/bin/bash
set -e

if [ "$(id -u)" = "0" ]; then
    mkdir -p /etc/multica /home/agent/.multica /home/agent/.codex /home/agent/wiki

    # git credential 配置 (root 阶段，因为 su -p 不传自定义环境变量)
    if [ -n "${GIT_TOKEN:-}" ]; then
        GIT_USERNAME="${GIT_USERNAME:-oauth2}"
        GIT_HOST="${GIT_HOST:-}"
        if [ -n "${GIT_HOST}" ]; then
            echo "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_HOST}" > /home/agent/.git-credentials
            chown agent:agent /home/agent/.git-credentials
            chmod 600 /home/agent/.git-credentials
        fi
    fi

    chown agent:agent /home/agent/.multica /home/agent /home/agent/.codex || true
    exec su -p -s /bin/bash agent -c "HOME=/home/agent exec $0"
fi

if [ ! -f /etc/multica/config.json ]; then
    echo "ERROR: /etc/multica/config.json not found (mount it as read-only volume)" >&2; exit 1
fi

cp /etc/multica/config.json ~/.multica/config.json

RUNTIME_NAME="${MULTICA_AGENT_RUNTIME_NAME:-Docker}"
DEVICE_NAME="${MULTICA_DAEMON_DEVICE_NAME:-Docker}"

# cc-proxy 暂未包含（repo private），恢复后取消注释：
# sudo -n cc-proxy start -c /home/agent/.cc-proxy &
#
# for i in $(seq 1 10); do
#     curl -sf http://127.0.0.1:15721/health && break
#     sleep 1
# done

multica daemon start --runtime-name "${RUNTIME_NAME}" --device-name "${DEVICE_NAME}"

wait
