#!/bin/bash
# Description: Common functions for deployments

require_command() {
    local COMMAND=$1
    if ! command -v "${COMMAND}" &> /dev/null; then
        log E "${COMMAND} not found"
        exit 1
    fi
}

require_kubectl_config() {
    if ! kubectl config view --minify &> /dev/null; then
        log E "kubectl not configured"
        exit 1
    fi
}


log() {
    local LEVEL=$1
    # 其它的參數，都是要當成訊息內容
    local MESSAGE="${*:2}"
    # shellcheck disable=SC2155
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    if tput setaf 1 &> /dev/null; then
        local COLOR_SUPPORT=1
    else
        local COLOR_SUPPORT=0
    fi

    if [ "$COLOR_SUPPORT" -eq 1 ]; then
        if [ "$LEVEL" == "I" ]; then
            COLOR=$(tput setaf 2) # green
        elif [ "$LEVEL" == "E" ]; then
            COLOR=$(tput setaf 1) # red
        else
            COLOR=$(tput sgr0)    # no color
        fi
        RESET=$(tput sgr0)
    else
        COLOR=""
        RESET=""
    fi

    if [ "$LEVEL" = "E" ]; then
        echo -e "${COLOR}[${TIMESTAMP}] [${LEVEL}] ${MESSAGE}${RESET}" >&2
    else
        echo -e "${COLOR}[${TIMESTAMP}] [${LEVEL}] ${MESSAGE}${RESET}"
    fi
}

k8s_wait_pods_ready() {
    local NAMESPACE=$1
    local MAX_RETRIES=5
    local RETRY_INTERVAL=5 # seconds
    local RETRY_COUNT=0

    log I "wait all pod of namespace ready: ${NAMESPACE} (10m)"
    # kubectl wait --for jsonpath='{.status.phase}=Active' --timeout=30s namespace/${NAMESPACE}
    while true; do
        log I "kubectl wait ${NAMESPACE}"
        ERROR=$(kubectl wait --for=condition=Ready pod --all -n "${NAMESPACE}" --timeout=10m 2>&1 > /dev/null)
        # shellcheck disable=SC2181
        if [ $? -eq 0 ]; then
            log I "All pods in ${NAMESPACE} are ready."
            return 0
        fi

        log D "ERROR: ${ERROR}"
        if [[ "${ERROR}" == *"no matching resources found"* ]]; then
            RETRY_COUNT=$((RETRY_COUNT+1))
            log I "No resources found in ${NAMESPACE}, retrying (${RETRY_COUNT}/${MAX_RETRIES})..."
            if [ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]; then
                sleep ${RETRY_INTERVAL}
                continue
            else
                echo "Max retries reached, exiting."
                exit 1
            fi
        else
            log E "Error occurred: ${ERROR}"
            exit 1
        fi
    done
}
