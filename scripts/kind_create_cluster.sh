#!/bin/bash -e

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source common.sh

if [ $# -lt 1 ]; then
    echo "Usage: $0 <main_net_iface> <cluster_name>"
    exit 1
fi

ARG_MAIN_NET_IFACE=$1
ARG_KS_NAME=$2

PRJ_PATH=$(realpath ../)
K8S_MAIN_IP=$(ifconfig "${ARG_MAIN_NET_IFACE}" | grep inet | grep -v inet6 | awk '{print $2}' | cut -d':' -f2)
if [ -z "${K8S_MAIN_IP}" ]; then
    log E "Can't get IP address of ${ARG_MAIN_NET_IFACE}"
    exit 1
fi

require_command kubectl
require_command docker
require_command kind

log I "Project path: ${PRJ_PATH}"
[ ! -d "${PRJ_PATH}/tmp" ] && mkdir -p "${PRJ_PATH}/tmp"

## Check cluster name exists
if kind get clusters | grep -q "${ARG_KS_NAME}"; then
    log I "kind cluster ${ARG_KS_NAME} already exists"
    exit 0
fi

## Create kind cluster
_kind_config_yaml="${PRJ_PATH}/assets/kind/kind_${ARG_KS_NAME}_config.yaml"
log I "create kind cluster ${ARG_KS_NAME}"
log I "Use $K8S_MAIN_IP to create kind_cluster_config.yaml for kind cluster"
_kind_config_yaml="${PRJ_PATH}/tmp/kind_${ARG_KS_NAME}_config.yaml"
cp -a ../assets/kind/kind_cluster_config_tmpl.yaml "${_kind_config_yaml}"
sed -i "s/K8S_MAIN_IP/${K8S_MAIN_IP}/g" "${_kind_config_yaml}"
_workshop_assets_path="${PRJ_PATH}/assets"
sed -i "s/WORKSHOP_ASSETS_PATH/${_workshop_assets_path//\//\\/}/g" "${_kind_config_yaml}"

kind create cluster --name="${ARG_KS_NAME}" --image="kindest/node:v1.27.3" --config="${_kind_config_yaml}" --wait=5m
kubectl cluster-info --context "kind-${ARG_KS_NAME}"
