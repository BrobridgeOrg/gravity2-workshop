#!/bin/bash -e 

cd "$(dirname "$0")"
source common.sh

# ask for confirmation
read -p "Are you sure to uninstall testdbs? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    log I "uninstall testdbs cancelled"
    exit 0
fi

log I "kubectl delete -f ../assets/testdbs/00-namespace.yaml"
kubectl delete -f ../assets/testdbs/00-namespace.yaml
