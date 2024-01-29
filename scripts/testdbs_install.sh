#!/bin/bash -e 

cd "$(dirname "$0")"
# shellcheck disable=SC1091
source common.sh

if kubectl get ns ws-testdbs &> /dev/null ; then
    log I "ws-testdbs already installed"
    kubectl -n ws-testdbs get pods
    exit 0
fi

log I "kubectl apply -f ../assets/testdbs/00-namespace.yaml"
kubectl apply -f ../assets/testdbs/00-namespace.yaml

log I "deploy test mssql server & create source database (TestDB)"
../assets/testdbs/test-mssql_source/10-create_source_db.sh
log I "  create table 'users'"
../assets/testdbs/test-mssql_source/users/01-create_src_tb.sh
log I "  insert data into 'users'"
../assets/testdbs/test-mssql_source/users/db-test/insert.sh
log I "  create table 'user_addresses'"
../assets/testdbs/test-mssql_source/user_addresses/01-create_src_tb.sh
log I "  insert data into 'user_addresses'"
../assets/testdbs/test-mssql_source/user_addresses/db-test/insert.sh

log I "deploy test mssql server & create target database (TargetTestDB)"
../assets/testdbs/test-mssql_target/20-create_target_db.sh
log I "  create table 'users'"
../assets/testdbs/test-mssql_target/users/01-create_target_tb.sh
log I "  create table 'user_addresses'"
../assets/testdbs/test-mssql_target/user_addresses/01-create_target_tb.sh

./testdbs_status.sh
