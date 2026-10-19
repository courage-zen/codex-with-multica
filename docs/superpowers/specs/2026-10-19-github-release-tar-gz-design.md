# codex-with-multica GitHub Release with tar.gz Assets — Design

Date: 2026-10-19
Status: Approved (Option A, user confirmed)
Reference: `~/code/dsh-with-multica` release flow (v0.1.0 / v0.1.1 both shipped amd64+arm64 tar.gz assets successfully)

## Goal

Give codex-with-multica the same release mechanism as dsh-with-multica: pushing a `v*` tag triggers CI to create a GitHub Release with downloadable `codex-with-multica-{amd64,arm64}.tar.gz` image archives (`docker save | gzip` of the GHCR images).

## Approach (Option A — mirror the reference repo)

CI already builds and pushes per-arch images on main pushes. We add a tag trigger and a downstream release job that pulls the just-pushed images back from GHCR and attaches them to a GitHub Release.

## Changes

### 1. `.github/workflows/build.yml`

- `on.push` gains `tags: ['v*']` (a tag push is still `event_name == 'push'`, so both matrix builds run and push images exactly as on main).
- New `release` job:
  - `needs: build`, `if: startsWith(github.ref, 'refs/tags/v')`
  - `permissions: contents: write, packages: read`
  - Steps:
    1. Checkout
    2. Extract tag version (`v` prefix stripped) and read `project.version` from `versions.yaml`
    3. **Guard**: fail with a clear message if tag version ≠ `project.version` (prevents a confusing `manifest unknown` on pull later)
    4. Login to GHCR with `GITHUB_TOKEN`
    5. For each arch: `docker pull --platform linux/{arch} ghcr.io/{repo}/base:{tag_version}-{arch}` then `docker save | gzip > codex-with-multica-{arch}.tar.gz`
       (note: codex images live under the `/base` suffix, unlike dsh which tags the repo root)
    6. `softprops/action-gh-release@v2` attaching both tar.gz files, release name `Release vX.Y.Z`

### 2. `README.md`

Add a "发布流程 / Release flow" section modeled on the dsh README:

- main push (paths-filtered) builds & pushes images
- `v*` tag creates the GitHub Release with tar.gz assets
- Release steps: bump `project.version` → commit & push main → `git tag vX.Y.Z && git push origin vX.Y.Z` → CI creates the release

## First Release (user-approved)

After merging the workflow change to main:

1. `git tag v0.1.0 && git push origin v0.1.0`
2. Verify the GitHub Release exists with both tar.gz assets downloadable

## Testing

- Workflow syntax validated by YAML parse + the actual CI run
- End-to-end verified by the v0.1.0 tag push (release job succeeds, assets present)
- Failure modes covered: version mismatch guard errors loudly before any pull

## Out of Scope

- No changes to Dockerfile, build.sh, versions.yaml component versions
- No checksums/sha256 files (reference repo doesn't ship them either; YAGNI)
