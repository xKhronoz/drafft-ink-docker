# Drafft.ink Docker

## Unofficial Docker configuration for Drafft.ink

This repository contains the Dockerfile and Docker Compose configuration for building and running the Drafft.ink application in a containerized environment.

## Dockerfile

The Dockerfile is structured in multiple stages to optimize the build process. It starts with a base image of Rust on Alpine Linux, installs the build dependencies it needs, and then builds the web application using wasm-pack. The `wasm-bindgen-cli` version is resolved from the upstream Drafft.ink `Cargo.lock` file during the build so the pinned version stays aligned with the source repository.

On `amd64` and `arm64`, the build downloads the matching prebuilt `wasm-bindgen` release archive for that lockfile version. On `arm`/`armv7`/`armv6`, it falls back to `cargo install wasm-bindgen-cli` with the same lockfile-derived version.

## Docker Compose

The Docker Compose configuration defines the services required to run the Drafft.ink application. The backend web server and the static web app are kept on the internal network, and two runnable reverse-proxy examples are provided so both the web app and the collaboration WebSocket can share one origin.

## Building and Running

To build and run the application using Docker Compose, follow these steps:

1. Clone the repository:

   ```bash
   git clone https://github.com/xkhronoz/drafft-ink-docker.git
   cd drafft-ink-docker
   ```

2. Build the Docker images:

   ```bash
   docker compose build
   ```

3. Start the nginx proxy example:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.nginx.yml up -d
   ```

   Or start the traefik proxy example:

   ```bash
   docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
   ```

4. Access the application in your web browser at `http://localhost:8080`.

The collaboration WebSocket stays on the same origin and is served from `/ws`, so the default client path works without a separate host or port.

## Notes

- This Docker configuration is unofficial and may not be maintained. It is intended for development and testing purposes.
- Ensure that you have Docker and Docker Compose installed on your system before running the commands.
- For any issues or contributions, please refer to the original Drafft.ink repository or create a pull request in this repository.

## License

This project is licensed under the AGPLv3 License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Patwie](https://github.com/PatWie) and [drafft-ink](https://github.com/PatWie/drafft-ink/tree/main) project for creating the original application.
- The Docker community for providing tools and resources for containerization.
