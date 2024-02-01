#!/bin/bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"

yam_file=mssql.yaml
sql_file="SourceDB.sql"

. config

kubectl -n ${ns} get svc "${svc_name}" &>/dev/null || {
  cat "${yam_file}" | sed \
    -e "s/#:NAME_SPACE:#/${ns}/" \
    -e "s/#:SVC_PORT:#/${svc_port}/" \
    -e "s/#:SVC_NAME:#/${svc_name}/" \
    | kubectl apply -f -
  # FIXME: wait for the service to be ready not use sleep
  sleep 3
  pod=$(kubectl -n ${ns} get pods | awk '/^'"${svc_name}"'-/{print $1}')
}

count=0
until [ $(kubectl -n ${ns} logs ${pod} 2>/dev/null | grep 'The tempdb database has [0-9]\+ data file(s).' | wc -l) -ge 2 ]; do
  ((count++))
  [ ${count} -ge 300 ] && {
    echo "${0##*/}: Error: timed out to detect DB server..."
    exit 1
  }
  echo "${0##*/}: waiting for DB server...${count}"
  sleep 1
done
echo "${0##*/}: DB server is ready..."

sql_command=$(cat ${sql_file} | sed -e "s/#:DB_NAME:#/${db_name}/g" -e "s/#:TABLE_NAME:#/${tb_name}/g")
msg=$(kubectl -n ${ns} exec -it ${pod} -- bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U ${sql_account} -P \"${sql_pass}\" -Q \"${sql_command};\"")
echo "$msg"
msg=$(echo "$msg" | grep -v "Changed database context")
[ "$msg" ] || echo "${0##*/}: DB '${db_name}' is created, and CDC is enabled."

