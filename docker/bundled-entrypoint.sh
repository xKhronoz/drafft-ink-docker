#!/bin/sh
set -eu

terminate() {
    if [ -n "${server_pid:-}" ]; then
        kill "${server_pid}" 2>/dev/null || true
    fi
    if [ -n "${nginx_pid:-}" ]; then
        kill "${nginx_pid}" 2>/dev/null || true
    fi
}

trap 'terminate' INT TERM

drafftink-server &
server_pid=$!

nginx -g 'daemon off;' &
nginx_pid=$!

while true; do
    if ! kill -0 "${server_pid}" 2>/dev/null; then
        wait "${server_pid}" || true
        terminate
        wait "${nginx_pid}" 2>/dev/null || true
        exit 1
    fi

    if ! kill -0 "${nginx_pid}" 2>/dev/null; then
        wait "${nginx_pid}" || true
        terminate
        wait "${server_pid}" 2>/dev/null || true
        exit 1
    fi

    sleep 1
done
