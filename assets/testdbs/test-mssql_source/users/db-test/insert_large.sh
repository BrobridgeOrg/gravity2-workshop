#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../../config
. ../config

data_file="source_large.txt"

keys=$(head -n1 $data_file)
val_lines=$(tail -n +2 $data_file)


lines_per_chunk=500
total_lines=$(wc -l < "$data_file")

count=1
for ((start_line = 1; start_line <= total_lines; start_line += lines_per_chunk)); do
    end_line=$((start_line + lines_per_chunk - 1))
    if [ "$end_line" -gt "$total_lines" ]; then
        end_line="$total_lines"
    fi

    echo "insert lines $start_line to $end_line:"
    unset values
    while read value; do
      if [ "${values}" ]; then
        values="${values}, (${value//\"/\\\"})"
      else
        values="(${value//\"/\\\"})"
      fi
      ((count++))
    done< <(tail -n+2 "${data_file}" | sed -n "${start_line},${end_line}p")

    ## run sql command
    sql_command="INSERT INTO ${tb_name} (${keys}) VALUES ${values}"
    #echo "$sql_command"
    #echo "----------------------------------------"
    #exit
    #continue
    kubectl -n ${ns} exec ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -d ${db_name} -Q \"${sql_command};\""
done
echo "count: ${count}"
