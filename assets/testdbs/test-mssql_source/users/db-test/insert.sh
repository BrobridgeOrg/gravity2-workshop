#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../../config
. ../config

data_file="source_1.txt"

keys=$(head -n1 $data_file)
val_lines=$(tail -n +2 $data_file)

while read value; do
  if [ "${values}" ]; then
    values="${values}, (${value//\"/\\\"})"
  else
    values="(${value//\"/\\\"})"
  fi
done< <(echo "$val_lines")

## run sql command
sql_command="INSERT INTO ${tb_name} (${keys}) VALUES ${values}"
#echo "$sql_command"
#exit
kubectl -n ${ns} exec ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -d ${db_name} -Q \"${sql_command};\""

