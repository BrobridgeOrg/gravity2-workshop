#!/bin/sh -e

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

_nats_url="${GRAVITY_NATS_SERVICE_HOST}:${GRAVITY_NATS_SERVICE_PORT}"

wait_nats_service() {
  	log I "Waiting for nats service to be ready..."
	timeout=90
	while ! nc -z -w 2 "${GRAVITY_NATS_SERVICE_HOST}" "${GRAVITY_NATS_SERVICE_PORT}"; do
		sleep 1
		timeout=$((timeout - 1))
		if [ "$timeout" -eq 0 ]; then
			log E "Timeout waiting for nats service"
			exit 1
		fi
	done
	log I "Nats service is ready!"
}

wait_dp_created() {
  	log I  "Waiting for dp '$1' to be created..."
	timeout=90
	while ! /gravity-cli product info "$1" --host="${_nats_url}" 1>/dev/null 2>&1; do
		sleep 1
		timeout=$((timeout - 1))
		if [ "$timeout" -eq 0 ]; then
			log E "Timeout waiting for dp '$1'"
			exit 1
		fi
	done
	log I  "DP '$1' is ready!"
}


wait_dp_created "${DP}"
log I "Data product '${DP}' is ready!"
