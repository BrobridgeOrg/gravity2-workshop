#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../config
. config

## show result
sql_command="SELECT * FROM ${tb_name}"
kubectl -n ${ns} exec -it ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -d ${db_name} -Q \"${sql_command};\""
