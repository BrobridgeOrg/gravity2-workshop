#!/bin/bash -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <kind cluster name>"
    exit 1
fi
KIND_CLUSTER_NAME="$1"
DOCKER_CONFIG="${HOME}/.docker/config.json"
if [ ! -f "${DOCKER_CONFIG}" ]; then
  echo "Please login docker first"
  exit 1
fi

for node in $(kind get nodes --name "${KIND_CLUSTER_NAME}"); do
  # the -oname format is kind/name (so node/name) we just want name
  node_name=${node#node/}
  # copy the config to where kubelet will look
  echo "Copying credentials to node name='${node_name}' ..."
  docker cp "${DOCKER_CONFIG}" "${node_name}:/var/lib/kubelet/config.json"
  # restart kubelet to pick up the config
  docker exec "${node_name}" systemctl restart kubelet.service
done

echo "Copy credentials to k8s node ...Done!"
