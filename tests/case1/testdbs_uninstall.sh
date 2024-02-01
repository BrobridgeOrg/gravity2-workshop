#!/bin/bash -e 

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source "../../scripts/common.sh"

log I "kubectl delete -f ./assets/testdbs/00-namespace.yaml"
kubectl delete -f ./assets/testdbs/00-namespace.yaml 2>/dev/null || true
