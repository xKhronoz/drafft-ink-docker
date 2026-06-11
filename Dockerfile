ARG DRAFFTINK_REPO=https://github.com/PatWie/drafft-ink.git
ARG DRAFFTINK_REF=main
ARG DRAFFTINK_SHA=
ARG IMAGE_VERSION=dev
ARG SOURCE_REPOSITORY=https://github.com/xkhronoz/drafft-ink-docker
ARG UPSTREAM_REPOSITORY=https://github.com/PatWie/drafft-ink

FROM rust:alpine3.23 AS base

ARG DRAFFTINK_REPO
ARG DRAFFTINK_REF
ARG DRAFFTINK_SHA

RUN apk add --no-cache build-base git musl-dev pkgconfig ca-certificates curl tar

WORKDIR /usr/src

RUN set -eux; \
    git init drafft-ink; \
    cd drafft-ink; \
    git remote add origin "${DRAFFTINK_REPO}"; \
    git fetch --depth 1 origin "${DRAFFTINK_REF}"; \
    if [ -n "${DRAFFTINK_SHA}" ]; then \
    git checkout "${DRAFFTINK_SHA}"; \
    else \
    git checkout FETCH_HEAD; \
    fi

WORKDIR /usr/src/drafft-ink

FROM base AS server-builder

RUN cargo build --release -p drafftink-server

FROM alpine:3.23 AS server

ARG IMAGE_VERSION
ARG DRAFFTINK_SHA
ARG SOURCE_REPOSITORY
ARG UPSTREAM_REPOSITORY

RUN apk add --no-cache ca-certificates wget && adduser -D -g '' appuser

WORKDIR /app

LABEL org.opencontainers.image.title="drafft.ink server" \
    org.opencontainers.image.description="Unofficial Drafft.ink server image" \
    org.opencontainers.image.version="${IMAGE_VERSION}" \
    org.opencontainers.image.revision="${DRAFFTINK_SHA}" \
    org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
    org.opencontainers.image.url="${SOURCE_REPOSITORY}" \
    io.drafftink.upstream-repository="${UPSTREAM_REPOSITORY}"

COPY --from=server-builder --chown=appuser:appuser /usr/src/drafft-ink/target/release/drafftink-server /usr/local/bin/drafftink-server

USER appuser

EXPOSE 3030

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:3030/health >/dev/null || exit 1

ENV RUST_LOG=drafftink_server=info,tower_http=info

CMD ["drafftink-server"]

FROM base AS web-builder

ARG TARGETARCH

RUN rustup target add wasm32-unknown-unknown

RUN cargo install wasm-pack --locked

RUN set -eux; \
    wasm_bindgen_version="$(awk 'BEGIN { found=0 } $0 == "name = \"wasm-bindgen\"" { found=1; next } found && $1 == "version" { gsub(/\"/, "", $3); print $3; exit }' Cargo.lock)"; \
    test -n "$wasm_bindgen_version"; \
    case "${TARGETARCH:-$(uname -m)}" in \
    amd64|x86_64) \
    wasm_bindgen_triple="x86_64-unknown-linux-musl"; \
    wasm_bindgen_archive="wasm-bindgen-${wasm_bindgen_version}-${wasm_bindgen_triple}.tar.gz"; \
    curl -fsSL -o "/tmp/${wasm_bindgen_archive}" \
    "https://github.com/rustwasm/wasm-bindgen/releases/download/${wasm_bindgen_version}/${wasm_bindgen_archive}"; \
    tar -xzf "/tmp/${wasm_bindgen_archive}" -C /tmp; \
    for wasm_bindgen_binary in wasm-bindgen wasm-bindgen-test-runner wasm2es6js; do \
    install -m 0755 "/tmp/wasm-bindgen-${wasm_bindgen_version}-${wasm_bindgen_triple}/${wasm_bindgen_binary}" "/usr/local/cargo/bin/${wasm_bindgen_binary}"; \
    done; \
    ;; \
    arm64|aarch64) \
    wasm_bindgen_triple="aarch64-unknown-linux-musl"; \
    wasm_bindgen_archive="wasm-bindgen-${wasm_bindgen_version}-${wasm_bindgen_triple}.tar.gz"; \
    curl -fsSL -o "/tmp/${wasm_bindgen_archive}" \
    "https://github.com/rustwasm/wasm-bindgen/releases/download/${wasm_bindgen_version}/${wasm_bindgen_archive}"; \
    tar -xzf "/tmp/${wasm_bindgen_archive}" -C /tmp; \
    for wasm_bindgen_binary in wasm-bindgen wasm-bindgen-test-runner wasm2es6js; do \
    install -m 0755 "/tmp/wasm-bindgen-${wasm_bindgen_version}-${wasm_bindgen_triple}/${wasm_bindgen_binary}" "/usr/local/cargo/bin/${wasm_bindgen_binary}"; \
    done; \
    ;; \
    arm|armv6*|armv7*) \
    cargo install wasm-bindgen-cli --version "${wasm_bindgen_version}" --locked; \
    ;; \
    *) \
    echo "Unsupported architecture for wasm-bindgen-cli install: ${TARGETARCH:-$(uname -m)}" >&2; \
    exit 1; \
    ;; \
    esac

RUN cd crates/drafftink-app \
    && wasm-pack build --target web --mode no-install --out-dir ../../web/pkg --no-default-features --release

FROM python:3.13-alpine AS web

ARG IMAGE_VERSION
ARG DRAFFTINK_SHA
ARG SOURCE_REPOSITORY
ARG UPSTREAM_REPOSITORY

RUN apk add --no-cache ca-certificates wget && adduser -D -g '' appuser

WORKDIR /site

LABEL org.opencontainers.image.title="drafft.ink web" \
    org.opencontainers.image.description="Unofficial Drafft.ink web image" \
    org.opencontainers.image.version="${IMAGE_VERSION}" \
    org.opencontainers.image.revision="${DRAFFTINK_SHA}" \
    org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
    org.opencontainers.image.url="${SOURCE_REPOSITORY}" \
    io.drafftink.upstream-repository="${UPSTREAM_REPOSITORY}"

COPY --from=web-builder --chown=appuser:appuser /usr/src/drafft-ink/web /site/web

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080 >/dev/null || exit 1

CMD ["python", "-m", "http.server", "8080", "--directory", "/site/web"]

FROM alpine:3.23 AS bundled

ARG IMAGE_VERSION
ARG DRAFFTINK_SHA
ARG SOURCE_REPOSITORY
ARG UPSTREAM_REPOSITORY

RUN apk add --no-cache ca-certificates nginx wget && adduser -D -g '' appuser

WORKDIR /app

LABEL org.opencontainers.image.title="drafftink-docker" \
    org.opencontainers.image.description="Unofficial all-in-one Drafft.ink app image" \
    org.opencontainers.image.version="${IMAGE_VERSION}" \
    org.opencontainers.image.revision="${DRAFFTINK_SHA}" \
    org.opencontainers.image.source="${SOURCE_REPOSITORY}" \
    org.opencontainers.image.url="${SOURCE_REPOSITORY}" \
    io.drafftink.upstream-repository="${UPSTREAM_REPOSITORY}"

COPY --from=server-builder /usr/src/drafft-ink/target/release/drafftink-server /usr/local/bin/drafftink-server
COPY --from=web-builder /usr/src/drafft-ink/web /usr/share/nginx/html
COPY nginx/bundled.conf /etc/nginx/nginx.conf
COPY docker/bundled-entrypoint.sh /usr/local/bin/bundled-entrypoint.sh

RUN chmod +x /usr/local/bin/drafftink-server /usr/local/bin/bundled-entrypoint.sh \
    && mkdir -p /run/nginx /var/lib/nginx/tmp /var/log/nginx \
    && chown -R appuser:appuser /app /run/nginx /var/lib/nginx /var/log/nginx /usr/share/nginx/html

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8000/health >/dev/null || exit 1

ENV RUST_LOG=drafftink_server=info,tower_http=info

CMD ["/usr/local/bin/bundled-entrypoint.sh"]
