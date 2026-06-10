# Unofficial Docker configuration for Drafft.ink

This repository contains the Dockerfile and Docker Compose configuration for building and running the Drafft.ink application in a containerized environment.

## Dockerfile

The Dockerfile is structured in multiple stages to optimize the build process. It starts with a base image of Rust on Alpine Linux, installs necessary dependencies, and then builds the web application using wasm-pack.

## Docker Compose

The Docker Compose configuration defines the services required to run the Drafft.ink application, including the web server and any additional services needed for the application to function properly.

## Building and Running

To build and run the application using Docker Compose, follow these steps:

1. Clone the repository:

   ```bash
   git clone https://github.com/xkhronoz/drafft-ink-docker.git
   cd drafft-ink-docker
   ```

2. Build the Docker images:

   ```bash
   docker-compose build
   ```

3. Start the services:

   ```bash
   docker-compose up
   ```

4. Access the application in your web browser at `http://localhost:8080`.
