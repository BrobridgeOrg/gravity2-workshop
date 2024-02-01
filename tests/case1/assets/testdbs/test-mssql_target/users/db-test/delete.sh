#!/bin/bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../../config
. ../config

## delete
sql_command="DELETE FROM ${tb_name}"
kubectl -n ${ns} exec -i ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -d ${db_name} -Q \"${sql_command};\""
