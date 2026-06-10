# Drafft.ink Docker

Unofficial Docker images, compose files, and GitHub Actions workflows for building and running [Drafft.ink](https://github.com/PatWie/drafft-ink).

## What’s Included

- A multi-stage [Dockerfile](Dockerfile) for the split `server`, `web`, and bundled `bundled` image targets.
- A base [docker-compose.yml](docker-compose.yml) for the split app services.
- Reverse proxy examples for [nginx](docker-compose.nginx.yml) and [traefik](docker-compose.traefik.yml).
- A single-container [docker-compose.bundle.yml](docker-compose.bundle.yml) for the all-in-one image.
- GitHub Actions workflows for Docker validation, DockerHub publishing, and GitHub Releases.

## Build Strategy

The build clones the upstream Drafft.ink repository during the image build and keeps the WebAssembly toolchain aligned with the upstream `Cargo.lock`.

- `amd64` and `arm64` use the matching prebuilt `wasm-bindgen` release archive.
- `arm`, `armv6`, and `armv7` fall back to `cargo install wasm-bindgen-cli` with the same lockfile-derived version.
- Release builds pin the upstream commit SHA from `main` and stamp that SHA into the image metadata.
- Final runtime images run as a non-root `appuser`.

## Local Usage

Clone the repository:

```bash
git clone https://github.com/xkhronoz/drafft-ink-docker.git
cd drafft-ink-docker
```

### Split services with nginx

Build the split images:

```bash
docker compose build
```

Start the nginx example:

```bash
docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d
```

### Split services with traefik

```bash
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
```

### Bundled all-in-one app image

Build and run the bundled app image:

```bash
docker compose -f docker-compose.bundle.yml up -d --build
```

You can also run the bundled app image directly:

```bash
docker build --target bundled -t drafftink-docker:local .
docker run --rm -p 8000:8000 drafftink-docker:local
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
docker build --target bundled -t drafftink-docker:local .
```

## CI and Releases

### Docker CI

The [Docker CI workflow](.github/workflows/docker-ci.yml) runs on pull requests, pushes to `main`, and manual dispatches. It:

- validates the nginx split compose config,
- validates the traefik split compose config,
- validates the bundled compose config,
- builds the `server`, `web`, and `bundled` targets.

### Versioned publishing and GitHub Releases

The [publish workflow](.github/workflows/dockerhub-publish.yml) runs on `v*` tags and manual dispatch.

Release contract:

- Repository tags must follow `vX.Y.Z`.
- The tag suffix must exactly match the upstream Drafft.ink `Cargo.toml` `workspace.package.version`.
- Releases build from the current upstream `main` commit only when that commit reports the same Cargo version.
- The upstream commit SHA is recorded in the GitHub Release notes and applied as image metadata for traceability.

Published Docker images:

- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server-latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:server-vX.Y.Z`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web-latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafft-ink-docker:web-vX.Y.Z`
- `docker.io/<DOCKERHUB_USERNAME>/drafftink-docker:latest`
- `docker.io/<DOCKERHUB_USERNAME>/drafftink-docker:vX.Y.Z`

Each successful publish also creates or updates a GitHub Release named after the repository tag.

Required repository secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Notes

- The split nginx and traefik examples both expose a single external port for web and WebSocket traffic.
- The bundled image exposes a single external port on `8000` and includes nginx plus the Drafft.ink server in one container.
- This repository is unofficial and intended for development and testing.
- If you run into issues, compare your setup against the upstream [Drafft.ink repository](https://github.com/PatWie/drafft-ink).

## Acknowledgments

- [Patwie](https://github.com/PatWie) and the [drafft-ink](https://github.com/PatWie/drafft-ink/tree/main) project for creating the original application.

## License

This project is licensed under the AGPLv3 License. See [LICENSE](LICENSE) for details.
