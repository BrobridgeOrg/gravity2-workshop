#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"

yam_file=mssql.yaml

. config

kubectl -n ${ns} get svc "${svc_name}" &>/dev/null && {
  cat "${yam_file}" | sed \
    -e "s/#:NAME_SPACE:#/${ns}/" \
    -e "s/#:SVC_PORT:#/${svc_port}/" \
    -e "s/#:SVC_NAME:#/${svc_name}/" \
    | kubectl delete -f -
}
