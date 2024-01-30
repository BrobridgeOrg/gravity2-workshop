#!/bin/bash -e

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source common.sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <cluster name>"
    exit 1
fi

ARG_KS_NAME=$1

if ! kind get clusters | grep -q "${ARG_KS_NAME}"; then
    log I "kind cluster ${ARG_KS_NAME} does not exist"
    exit 0
fi

kind load docker-image ghcr.io/brobridgeorg/gravity/gravity-dispatcher:3de6b01 --name="${ARG_KS_NAME}"
kind load docker-image busybox:1.28 --name="${ARG_KS_NAME}"
kind load docker-image mcr.microsoft.com/mssql/server:2019-latest --name="${ARG_KS_NAME}"
kind load docker-image brobridgehub/nats-server:v1.3.4 --name="${ARG_KS_NAME}"
kind load docker-image ghcr.io/brobridgeorg/atomic/atomic:v0.0.5-20231012-ubi --name="${ARG_KS_NAME}"
kind load docker-image ghcr.io/brobridgeorg/gravity/gravity-adapter-mssql:v3.0.5 --name="${ARG_KS_NAME}"
