#!/bin/bash -e

docker pull ghcr.io/brobridgeorg/gravity/gravity-dispatcher:3de6b01
docker pull ghcr.io/brobridgeorg/gravity/gravity-adapter-mssql:v3.0.5
docker pull busybox:1.28
docker pull brobridgehub/nats-server:v1.3.4
docker pull mcr.microsoft.com/mssql/server:2019-latest
docker pull ghcr.io/brobridgeorg/atomic/atomic:v0.0.5-20231012-ubi
