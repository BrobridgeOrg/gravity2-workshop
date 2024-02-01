#!/bin/bash -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <main net iface> <test case name> [renew_all | renew_db]"
    exit 1
fi

# 外部傳入參數
MAIN_NET_IFACE=$1  # 主要網路介面名稱, e.g: eth0, enp4s0
TC_NAME=${2}      # 測試案例名稱，為 `tests/<test case name>` 的目錄名稱
RWNEW_OPT=${3:-use_exist_ks} # 當為 `renew_all` 會重新建立 kind cluster & db, 當為 `renew_db` 只會重新建立 db

# 內部變數
KIND_K8S_VER="v1.27.3" # kind 支援的 k8s v1.27.x 版本 (2023/11/20)
PROJECT_PATH=$(pwd)
TC_PATH="${PROJECT_PATH}/tests/${TC_NAME}"
KS_NAME="${TC_NAME}-cluster"
TC_NS="${TC_NAME}"
_start_time=$(date +%s)

if [ ! -f "${PROJECT_PATH}/go.mod" ]; then
    echo "Please run this script in the root directory of the project"
    exit 1
fi

if [ ! -d "${TC_PATH}" ]; then
    echo "Test case directory not found: ${TC_PATH}"
    exit 1
fi

# shellcheck disable=SC1091
source "${PROJECT_PATH}/scripts/common.sh"

[ ! -d "${PROJECT_PATH}/tmp" ] && mkdir -p "${PROJECT_PATH}/tmp"

# 安裝 kubectl & kind
if ! command -v kubectl &> /dev/null ; then
    log I "install kubectl ${KIND_K8S_VER}"
    curl -sLo /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/${KIND_K8S_VER}/bin/linux/amd64/kubectl"
    chmod +x /usr/local/bin/kubectl 
fi 

if ! command -v kind &> /dev/null ; then
    log I "install kind 0.20.0"
    curl -sLo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64 
    chmod +x /usr/local/bin/kind
fi

cd "${TC_PATH}"
K8S_MAIN_IP=$(ifconfig "${MAIN_NET_IFACE}" | grep inet | grep -v inet6 | awk '{print $2}' | cut -d':' -f2)

if [ "${RWNEW_OPT}" = "renew_all" ]; then
    # check if old kind cluster exist, delete it
    if kind get clusters | grep -q "${KS_NAME}" 2>/dev/null ; then
        log I "delete old kind cluster ${KS_NAME}"
        kind delete cluster --name "${KS_NAME}" || true
    fi

    log I "create kind cluster ${KS_NAME}"
    log I "Use $K8S_MAIN_IP to create kind_cluster_config.yaml for kind cluster"
    _kind_config_yaml="${PROJECT_PATH}/tmp/kind_${KS_NAME}_config.yaml"
    cp -a kind_cluster_config_tmpl.yaml "${_kind_config_yaml}"
    sed -i "s/K8S_MAIN_IP/${K8S_MAIN_IP}/g" "${_kind_config_yaml}"
    # prepare host path for kind cluster
    _test_case_assets_path="${TC_PATH}/assets"
    sed -i "s/WORKSHOP_ASSETS_PATH/${_test_case_assets_path//\//\\/}/g" "${_kind_config_yaml}"
    # create kind cluster
    kind create cluster --name="${KS_NAME}" "--image=kindest/node:${KIND_K8S_VER}" --config="${_kind_config_yaml}" --wait=5m
    # show k8s cluster info
    kubectl cluster-info --context "kind-${KS_NAME}"

    # 下面的腳本會將 "${HOME}/.docker/config.json" 複製到 kind k8s cluster 裡面
    # 以便部署時，可以從 docker hub, github container registry 下載 docker image 時
    #   * 避免手動執行腳時，本機機器 docker hub pull rate limit 的問題
    #   * 有權限 docker pull ghcr.io 的 private docker image
    # A. 本機開發時，請先在 host 上執行過 
    #   docker login -u {YOUR_DOCKER_HUB_USERNAME}
    #   docker login -u {YOUR_GITHUB_USERNAME} ghcr.io
    # B. github action -> earhtly -P +ci-pull-request
    #   下面判斷環境變數，進行 docker login 在 earthly container 裡面，產生 "${HOME}/.docker/config.json"
    if [[ -n $GITHUB_TOKEN ]] && [[ -n $GITHUB_ACTOR ]]; then
        echo -n "${GITHUB_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin
    fi
    if [[ -n $DOCKER_HUB_USERNAME ]] && [[ -n $DOCKER_HUB_ACCESS_TOKEN ]]; then
        echo -n "${DOCKER_HUB_ACCESS_TOKEN}" | docker login -u "${DOCKER_HUB_USERNAME}" --password-stdin
    fi

    if [ -f "${HOME}/.docker/config.json" ]; then
        # copy dockerconfigjson to kind cluster
        log I "copy dockerconfigjson to kind cluster"
        "${PROJECT_PATH}/scripts/kind_dockerconfigjson.sh" "${KS_NAME}"
    fi

    # 使用 EARTHLY_CI 這個環境變數，判斷是否由 earthly 執行的
    # 只有在本機直接執行這個腳本時，才需要將 docker image 載入到 kind cluster
    # ref: https://docs.earthly.dev/docs/earthfile/builtin-args
    log D "EARTHLY_CI = '${EARTHLY_CI}'"
    if [ "${EARTHLY_CI}" = "" ]; then
        # load docker image to kind cluster when your are run on local machine
        log I "load docker images to kind cluster"
        "${PROJECT_PATH}/scripts/kind_load_images.sh" "${KS_NAME}"
    fi
fi

# check namespace exist, if exist, delete it
if kubectl get ns | grep -q "${TC_NS}" 2>/dev/null ; then
    log I "delete old test case namespace '${TC_NS}'"
    kubectl delete ns "${TC_NS}" || true
fi

# check if old pv "ws-assets-pv" exist, delete it
if kubectl get pv | grep -q "ws-assets-pv" 2>/dev/null ; then
    log I "delete old pv ws-assets-pv in the global"
    kubectl delete pv ws-assets-pv || true
fi

# if RWNEW_OPT is renew_all, renew_db, then deploy db
if [[ "${RWNEW_OPT}" = "renew_all" ]] || [[ "${RWNEW_OPT}" = "renew_db" ]]; then
    log I "renew testdbs to test case's kind cluster"
    ./testdbs_uninstall.sh
    ./testdbs_install.sh
else
    log I "use exist testdbs in test case's kind cluster"
    log I "clean all records in source table 'users'"
    ./assets/testdbs/test-mssql_source/users/db-test/delete.sh
    log I "clean all records in target table 'users'"
    ./assets/testdbs/test-mssql_target/users/db-test/delete.sh
fi

# deploy yamls to test case kind cluster
log I "deploy yamls-1"
kubectl apply -f "${TC_PATH}/assets/yamls-1"
k8s_wait_pods_ready "${TC_NS}"

log I "deploy yamls-2"
kubectl apply -f "${TC_PATH}/assets/yamls-2"
k8s_wait_pods_ready "${TC_NS}"

log I "deploy yamls-3"
kubectl apply -f "${TC_PATH}/assets/yamls-3"
k8s_wait_pods_ready "${TC_NS}"

log I "=== services ==="
kubectl -n "${TC_NS}" get svc
log I "=== '$TC_NAME' setup done"


log I "=============================="
log I " feature test steps"
log I "=============================="
log I " 1. insert data into source table 'users'"
./assets/testdbs/test-mssql_source/users/db-test/insert.sh
sleep 5
log I " 2. Check CDC insert event in dispatcher"
log I "    [TBD]"
log I " 3. Check data in target table 'users'"
./assets/testdbs/test-mssql_target/users/db-test/query_count.sh

log I "=============================="
log I " teardown test case"
log I "=============================="
log I "1. delete adapter"
kubectl delete -f "${TC_PATH}/assets/yamls-3"
k8s_wait_pods_ready "${TC_NS}"
log I "2. delete all recoreds in target table 'users'"
./assets/testdbs/test-mssql_target/users/db-test/delete.sh

_end_time=$(date +%s)
log I "integration test done, elapsed time: $((_end_time-_start_time)) seconds"
