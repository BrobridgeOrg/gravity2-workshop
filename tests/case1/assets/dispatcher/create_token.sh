#!/bin/sh

cd "$(dirname "$0")" || exit 1

log() {
    LEVEL=$1
    # 其它的參數，都是要當成訊息內容
	shift
	MESSAGE="$*"
    # shellcheck disable=SC2155
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${TIMESTAMP}] [${LEVEL}] ${MESSAGE}"
}

log I "Create token for atomic"
/gravity-cli token create --desc "atomic" --enabled true -s gravity-nats:4222

