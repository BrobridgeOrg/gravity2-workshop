#!/bin/bash -e

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source "../../scripts/common.sh"

if ! kubectl get ns ws-testdbs &> /dev/null ; then
    log I "testdbs not installed, please run ./testdbs_install.sh first"
    exit 0
fi

# k8s kubeconfig server ip
K8S_MAIN_IP=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' | awk -F[/:] '{print $4}')
SRCDB_PORT=$(kubectl -n ws-testdbs get svc | awk '/mssql-testdbs/ {split($5,a,":"); split(a[2],b,"/"); print b[1]}')

log I "To access mssql server from other host, please use following info"
source ./assets/testdbs/test-mssql_source/config
log I " * source mssql: ${K8S_MAIN_IP}:${SRCDB_PORT}"
log I "   database: ${db_name}"
log I "   username: ${sql_account}"
log I "   password: ${sql_pass}"
source ./assets/testdbs/test-mssql_target/config
log I " * target mssql: ${K8S_MAIN_IP}:${SRCDB_PORT}"
log I "   database: ${db_name}"
log I "   username: ${sql_account}"
log I "   password: ${sql_pass}"
log I " * useful scripts"
log I "   query source tables"
log I "   ./assets/testdbs/test-mssql_source/users/db-test/query.sh"
log I "   ./assets/testdbs/test-mssql_source/user_addresses/db-test/query.sh"
log I "   query target tables"
log I "   ./assets/testdbs/test-mssql_target/users/db-test/query.sh"
log I "   ./assets/testdbs/test-mssql_target/user_addresses/db-test/query.sh"
log I "=== pods ==="
kubectl -n ws-testdbs get pods
log I "=== services ==="
kubectl -n ws-testdbs get svc
log I "=== pvc ==="
kubectl -n ws-testdbs get pvc
