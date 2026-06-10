FROM rust:alpine3.23 AS base

RUN apk add --no-cache build-base git musl-dev pkgconfig

WORKDIR /usr/src

RUN git clone --depth 1 https://github.com/PatWie/drafft-ink.git drafft-ink

WORKDIR /usr/src/drafft-ink

FROM base AS server-builder

RUN cargo build --release -p drafftink-server

FROM alpine:3.23 AS server

RUN apk add --no-cache ca-certificates wget && adduser -D -g '' appuser

WORKDIR /app

COPY --from=server-builder /usr/src/drafft-ink/target/release/drafftink-server /usr/local/bin/drafftink-server

USER appuser

EXPOSE 3030

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3030/health >/dev/null || exit 1

ENV RUST_LOG=drafftink_server=info,tower_http=info

CMD ["drafftink-server"]

FROM base AS web-builder

ENV RUST_LOG=debug

RUN rustup target add wasm32-unknown-unknown

RUN cargo install wasm-pack --locked

RUN cargo install wasm-bindgen-cli --version 0.2.106 --locked

RUN cd crates/drafftink-app \
    && wasm-pack build --target web --mode no-install --out-dir ../../web/pkg --no-default-features --release

FROM python:3.13-alpine AS web

RUN apk add --no-cache ca-certificates wget

WORKDIR /site

COPY --from=web-builder /usr/src/drafft-ink/web /site/web

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080 >/dev/null || exit 1

CMD ["python", "-m", "http.server", "8080", "--directory", "/site/web"]
