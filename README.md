# Drafft.ink Docker

Unofficial Docker images, Compose examples, and GitHub Actions workflows for building and running [Drafft.ink](https://github.com/PatWie/drafft-ink).

## Overview

This repository builds Drafft.ink directly from the upstream Git repository during the Docker build and ships three runtime targets:

- `server`: the `drafftink-server` backend on port `3030`
- `web`: the static web bundle served on port `8080`
- `bundled`: nginx plus the backend in one container on port `8000`

The split deployment examples keep the backend and frontend in separate containers and add either nginx or Traefik as the reverse proxy. The bundled deployment keeps everything in a single container and exposes the app and WebSocket endpoint from one port.

## Repository Layout

- [Dockerfile](Dockerfile): multi-stage build for `server`, `web`, and `bundled`
- [docker-compose.yml](docker-compose.yml): base split-service stack
- [docker-compose.nginx.yml](docker-compose.nginx.yml): nginx reverse proxy for the split stack
- [docker-compose.traefik.yml](docker-compose.traefik.yml): Traefik reverse proxy for the split stack
- [docker-compose.bundle.yml](docker-compose.bundle.yml): all-in-one bundled container
- [docker-bake.hcl](docker-bake.hcl): Buildx Bake targets for local CI and release publishing
- [.github/workflows/docker-ci.yml](.github/workflows/docker-ci.yml): compose validation plus image builds
- [.github/workflows/dockerhub-publish.yml](.github/workflows/dockerhub-publish.yml): tagged multi-arch publishing and GitHub Releases

## Prerequisites

- Docker with Compose v2 support
- Internet access during builds, because the Docker build clones the upstream Drafft.ink repository and downloads Rust/WebAssembly tooling

## Quick Start

Clone the repository:

```bash
git clone https://github.com/xkhronoz/drafft-ink-docker.git
cd drafft-ink-docker
```

### Option 1: split services behind nginx

```bash
docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d --build
```

Open `http://localhost:8000`.

### Option 2: split services behind Traefik

```bash
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d --build
```

Open `http://localhost:8000`.

### Option 3: bundled all-in-one container

```bash
docker compose -f docker-compose.bundle.yml up -d --build
```

Open `http://localhost:8000`.

In every mode, the collaboration WebSocket is available on the same origin at `/ws`.

## Direct Docker Builds

Build individual images without Compose:

```bash
docker build --target server -t drafftink-server:local .
docker build --target web -t drafftink-web:local .
docker build --target bundled -t drafftink-docker:local .
```

Run the bundled image directly:

```bash
docker run --rm -p 8000:8000 drafftink-docker:local
```

## Build Inputs

The [Dockerfile](Dockerfile) and [docker-bake.hcl](docker-bake.hcl) support these build arguments:

- `DRAFFTINK_REPO`: upstream Git repository URL to clone
- `DRAFFTINK_REF`: branch, tag, or ref to fetch from the upstream repository
- `DRAFFTINK_SHA`: exact upstream commit SHA to check out after fetch
- `IMAGE_VERSION`: version string applied to OCI image metadata
- `SOURCE_REPOSITORY`: source repository URL stamped into image metadata
- `UPSTREAM_REPOSITORY`: upstream project URL stamped into image metadata

Example: build the bundled image from a specific upstream commit:

```bash
docker build \
  --target bundled \
  --build-arg DRAFFTINK_REF=main \
  --build-arg DRAFFTINK_SHA=<upstream-commit-sha> \
  --build-arg IMAGE_VERSION=dev \
  -t drafftink-docker:local .
```

## Build Notes

- The build uses Rust on Alpine and clones the upstream Drafft.ink source into the build context at image build time.
- The `web` target extracts the `wasm-bindgen` version from the upstream `Cargo.lock` so the WebAssembly toolchain matches the upstream project.
- `amd64` and `arm64` use prebuilt `wasm-bindgen` release archives.
- `arm`, `armv6`, and `armv7` fall back to `cargo install wasm-bindgen-cli` with the same lockfile-derived version.
- Runtime containers run as the non-root `appuser`.
- Health checks use `/health` for the `server` and `bundled` targets, and `/` for the `web` target.

## Multi-Arch Builds With Bake

The [docker-bake.hcl](docker-bake.hcl) file defines `server`, `web`, and `bundled` targets for `linux/amd64` and `linux/arm64`.

Build them locally with Buildx:

```bash
docker buildx bake
```

Override release metadata when needed:

```bash
docker buildx bake \
  --set *.args.IMAGE_VERSION=v0.1.0 \
  --set *.args.DRAFFTINK_SHA=<upstream-commit-sha>
```

## CI and Releases

### Docker CI

The [Docker CI workflow](.github/workflows/docker-ci.yml) runs on pushes to `main`, pull requests targeting `main`, and manual dispatches. It:

- validates the nginx split compose config
- validates the Traefik split compose config
- validates the bundled compose config
- builds the Bake targets without pushing

### Publishing

The [publish workflow](.github/workflows/dockerhub-publish.yml) runs on `v*` tags and manual dispatch.

Release contract:

- repository tags must follow `vX.Y.Z`
- the tag suffix must exactly match the upstream Drafft.ink `workspace.package.version`
- release publishing clones upstream `main`, verifies the version there, and records the upstream commit SHA in image metadata and GitHub Release notes

Published image tags:

- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server-latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server-vX.Y.Z`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web-latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web-vX.Y.Z`
- `docker.io/<DOCKERHUB_USERNAME>/drafftink-docker:latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafftink-docker:vX.Y.Z`

Required repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Notes

- The nginx and Traefik examples both expose a single external port on `8000`.
- The bundled image serves the frontend directly from nginx and proxies `/ws` and `/health` to the backend running in the same container.
- The Traefik example enables `--api.insecure=true` inside the sample config and is intended for local development, not production hardening.
- This repository is unofficial and primarily aimed at development, testing, and self-hosted packaging experiments.

## Acknowledgments

- [PatWie](https://github.com/PatWie) and the [drafft-ink](https://github.com/PatWie/drafft-ink/tree/main) project for the original application.

## License

This project is licensed under the AGPLv3 License. See [LICENSE](LICENSE) for details.
