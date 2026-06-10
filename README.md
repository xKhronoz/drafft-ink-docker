# Drafft.ink Docker

Unofficial Docker images, compose overlays, and CI workflows for building and running [Drafft.ink](https://github.com/PatWie/drafft-ink).

## What’s Included

- A multi-stage [Dockerfile](Dockerfile) for the Rust server and the WASM web build.
- A base [docker-compose.yml](docker-compose.yml) file for the app services.
- Reverse proxy examples for [nginx](docker-compose.nginx.yml) and [traefik](docker-compose.traefik.yml).
- GitHub Actions workflows for Docker validation and DockerHub publishing.

## Build Strategy

The build resolves the `wasm-bindgen-cli` version from the upstream Drafft.ink `Cargo.lock` file so the pinned version stays aligned with the source repository.

- `amd64` and `arm64` use the matching prebuilt `wasm-bindgen` release archive.
- `arm`, `armv6`, and `armv7` fall back to `cargo install wasm-bindgen-cli` with the same lockfile-derived version.

The final runtime images run as a non-root `appuser`.

## Quick Start

Clone the repository:

```bash
git clone https://github.com/xkhronoz/drafft-ink-docker.git
cd drafft-ink-docker
```

Build the app images:

```bash
docker compose build
```

Start the nginx example:

```bash
docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d
```

Or start the traefik example:

```bash
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
```

Open the app at:

```text
http://localhost:8000
```

The collaboration WebSocket stays on the same origin and is served from `/ws`.

## Direct Docker Builds

If you want to build the images without compose:

```bash
docker build --target server -t drafft-ink-server:local .
docker build --target web -t drafft-ink-web:local .
```

## CI and Publishing

### Docker CI

The [Docker CI workflow](.github/workflows/docker-ci.yml) runs on pull requests, pushes to `main`, and manual dispatches. It:

- validates the nginx compose overlay,
- validates the traefik compose overlay,
- builds the `drafftink-server` and `drafftink-web` targets.

### DockerHub Publishing

The [publish workflow](.github/workflows/dockerhub-publish.yml) runs on `v*` tags and manual dispatch.

It publishes these images:

- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server-latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web-latest`

Required repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Notes

- The nginx and traefik overlays both expose a single external port for web and WebSocket traffic.
- This repository is unofficial and intended for development and testing.
- If you run into issues, compare your setup against the upstream [Drafft.ink repository](https://github.com/PatWie/drafft-ink).

## Acknowledgments

- [Patwie](https://github.com/PatWie) and [drafft-ink](https://github.com/PatWie/drafft-ink/tree/main) project for creating the original application.

## License

This project is licensed under the AGPLv3 License. See [LICENSE](LICENSE) for details.
