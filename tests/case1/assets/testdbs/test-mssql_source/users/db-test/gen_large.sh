#!/bin/env bash

[ "${0##*/}" = "$0" ] || cd "${0%/*}"

max=${1:-2000}
ini=21
data_file="source_large.txt"

[ ${ini} -le ${max} ] || max=$((max+ini))

echo "[id], [created_at], [updated_at], [username], [password], [email]" > "${data_file}"
for ((n=${ini};n<=${max};n++)); do
  time=$(date +%FT%T.%7N | tr 'T,' ' .')
  name1=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 7 | head -n 1)
  name2=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 51 | head -n 1)
  name3=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 7 | head -n 1)
  name4=$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w 7 | head -n 1)
  echo "N'${n}', N'${time} +08:00', N'${time} +08:00', N'${name1}', N'${name2}', N'${name3}@${name4}.edu'"
done >> "${data_file}"
