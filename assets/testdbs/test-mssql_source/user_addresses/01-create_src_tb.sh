#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../config
. config

sql_file="SrcTable.sql"

sql_command=$(cat ${sql_file} | sed -e "s/#:DB_NAME:#/${db_name}/g" -e "s/#:TABLE_NAME:#/${tb_name}/g")
kubectl -n ${ns} exec -it ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -Q \"${sql_command};\""
