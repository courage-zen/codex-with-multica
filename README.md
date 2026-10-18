# codex-with-multica

Docker 容器化的 Codex CLI + multica agent 部署方案（agents-with-multica 的 Codex 版镜像）。

## 与 agents-with-multica 的区别

| | agents-with-multica (base) | codex-with-multica (本项目) |
|---|---|---|
| Agent CLI | Claude Code (npm, 需 Node 22 运行时) | Codex CLI (Rust musl 静态二进制, 零运行时依赖) |
| 基础镜像 | `node:22-bookworm-slim` | `debian:bookworm-slim` |
| Codex 接入 | — | cc-proxy (Codex Responses 协议) |

## 项目结构

- `base/` — 基础镜像（Codex CLI + cc-proxy + multica）
- `versions.yaml` — 版本号（ARG 必须由此传入，禁止硬编码）
- `build.sh` — 本地构建脚本

## 镜像架构

```
debian:bookworm-slim
  ├── codex  (musl 静态二进制, /usr/local/bin/codex)
  ├── cc-proxy (gnu 二进制)
  ├── multica (静态 Go 二进制)
  └── git / ca-certificates / curl / sudo / openssh-client
```

注：codex 官方只发布 musl 静态链接变体，在 debian (glibc) 上可直接运行。
cc-proxy 是 private 仓库，CI 用 `CC_PROXY_TOKEN` secret 下载其 release 资产。

## 私有依赖：cc-proxy

cc-proxy (`courage-zen/cc-proxy`) 是 private 仓库，默认 `GITHUB_TOKEN` 访问不到
其 release 资产（404）。CI 通过专用 PAT 下载：

1. 创建 fine-grained PAT：Repository access 选 **Only select → courage-zen/cc-proxy**，
   Permissions 只开 **Contents → Read-only**
2. 存为 codex-with-multica 仓库 secret：`CC_PROXY_TOKEN`
3. CI 的 "Download cc-proxy (private repo)" 步骤用它认证下载

本地构建 `build.sh` 用本机已认证的 gh（需对 cc-proxy 有读权限）。

## 构建命令

```bash
./build.sh amd64
./build.sh arm64
```

CI：push 到 main 自动构建 amd64/arm64 并推送到 GHCR。

## 运行

容器启动时需要挂载：

- `/etc/multica/config.json` — multica 配置（只读）
- `/home/agent/.cc-proxy/config.yaml` — cc-proxy 配置（只读）

Codex CLI 的配置/认证在 `/home/agent/.codex`。

## 版本管理

`versions.yaml`:

```yaml
project:
  version: "0.1.0"
cc_proxy:
  version: "0.3.0"
multica:
  version: "0.4.43"
codex:
  version: "0.163.0"
```
