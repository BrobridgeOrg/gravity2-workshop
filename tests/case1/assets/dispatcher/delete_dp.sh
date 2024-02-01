#!/bin/sh
cd "$(dirname "$0")" || exit 1

if [ "$1" ]; then
        DP="$1"
else
        echo "Missing argument. please provide DP name."
        exit 1
fi

log() {
    LEVEL=$1
    # 其它的參數，都是要當成訊息內容
	shift
	MESSAGE="$*"
    # shellcheck disable=SC2155
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] [${LEVEL}] ${MESSAGE}"
}

log I "Delete ruleset - ${DP}Initialize"
/gravity-cli product ruleset delete "${DP}" "${DP}Initialize" -s gravity-nats:4222

log I "Delete ruleset - ${DP}Create"
/gravity-cli product ruleset delete "${DP}" "${DP}Create" -s gravity-nats:4222

log I "Delete ruleset - ${DP}Update"
/gravity-cli product ruleset delete "${DP}" "${DP}Update" -s gravity-nats:4222

log I "Delete ruleset - ${DP}Delete"
/gravity-cli product ruleset delete "${DP}" "${DP}Delete" -s gravity-nats:4222

sleep 2
log I "Delete data product - ${DP}"
/gravity-cli product delete "${DP}" -s gravity-nats:4222
