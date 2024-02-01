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

# when you run this script in the gravity-dispatcher pod
# it is has "/gravity-cli" installed and configured environment variables
_nats_url="${GRAVITY_DISPATCHER_GRAVITY_HOST}:${GRAVITY_DISPATCHER_GRAVITY_PORT}"

wait_nats_service() {
  	log I "Waiting for nats service to be ready..."
	timeout=90
	while ! nc -z -w 2 gravity-nats 4222; do
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

create_dp_and_wait_created() {
	dp=$1
	nats_url=$2
	max_retries=3
	retries=0

	log I "Data product '${dp}' ...creating"
	while [ $retries -lt $max_retries ]; do
		/gravity-cli product create "${dp}" --desc="${dp} pd" --enabled \
			--schema="./schema_${dp}.json" -s "${nats_url}"
		exit_code=$?

		if [ $exit_code -eq 0 ]; then
			log I "Waiting for dp '$1' to be created..."
			timeout=90
			while ! /gravity-cli product info "$1" --host="${nats_url}" 1>/dev/null 2>&1; do
				sleep 1
				timeout=$((timeout - 1))
				if [ "$timeout" -eq 0 ]; then
					log E "Timeout waiting for dp '$1'"
					exit 1
				fi
			done
			log I "Data product '${DP}' ...created"
			return
		else
			retries=$((retries + 1))
			log I "Data product '${DP}' ...retrying"
			sleep 3
		fi
	done

	log E "Data product '${DP}' ...failed to create after $max_retries retries"
	exit 1
}

create_rulesets() {
	dp=$1
	ruleset_name=$2
	nats_url=$3
	max_retries=3
	retries=0

	log I "Rulesets '${ruleset_name}' ...creating"
	while [ $retries -lt $max_retries ]; do
		/gravity-cli product ruleset add "${dp}" "${ruleset_name}" --enabled \
			--event="${ruleset_name}" --method=create --handler=./handler.js \
			--schema="./schema_${dp}.json" -s "${nats_url}"
		exit_code=$?

		if [ $exit_code -eq 0 ]; then
			log I "Rulesets '${ruleset_name}' ...created"
			return
		else
			retries=$((retries + 1))
			log I "Rulesets '${ruleset_name}' ...retrying"
			sleep 3
		fi
	done

	log E "Rulesets '${ruleset_name}' ...failed to create after $max_retries retries"
	exit 1
}

wait_nats_service

log I "Current directory: $(pwd)"
create_dp_and_wait_created "${DP}" "${_nats_url}"
create_rulesets "${DP}" "${DP}Initialize" "${_nats_url}"
create_rulesets "${DP}" "${DP}Create" "${_nats_url}"
create_rulesets "${DP}" "${DP}Update" "${_nats_url}"
create_rulesets "${DP}" "${DP}Delete" "${_nats_url}"

log I "Create rulesets for data product '${DP}' done!"
