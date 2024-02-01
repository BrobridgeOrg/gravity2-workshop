#!/bin/bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"
. ../../config
. ../config

data_file="update.txt"

keys=($(head -n1 $data_file | tr ',][' ' '))
val_lines=$(tail -n +2 $data_file)

#echo "${keys[@]}"
#echo "${val_lines}"
#exit

count=1
while read values; do
  echo sql command: $count
  ((count++))
  ## run sql command

  declare -A kv
  for ((n=0;n<${#keys[@]};n++)); do
    value=$(echo "$values" | awk -F', ' '{print $'$((n+1))'}')
    eval kv[\\${keys[$n]}]="\"${value}\""
  done
  set_kv=$(for i in "${!kv[@]}"; do 
      [ ${i} = id ] && continue
      echo -n "$i=${kv[$i]}, "
    done
    echo)
  
  # set WHERE criteria here!
  update_line="${set_kv%,*} WHERE id=${kv[id]}" 

  sql_command="UPDATE ${tb_name} SET ${update_line};"
  echo "${sql_command}"
  #continue
  kubectl -n ${ns} exec ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -d ${db_name} -Q \"${sql_command};\""
done< <(echo "$val_lines" | grep -v '^$')
