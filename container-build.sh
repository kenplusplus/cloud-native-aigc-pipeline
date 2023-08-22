#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")

REGISTER="gar-registry.caas.intel.com/cpio/"
CONTAINER_NAME="cnagc-fastchat"
CNAGC_FASTCHAT_ROOT=${CURR_DIR}/container/cnagc-fastchat
CNAGC_FASTCHAT_K8S_ROOT=${CURR_DIR}/container/cnagc-fastchat-k8s


usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...
  -c [cnagc-fastchat|cnagc-fastchat-k8s] the container name for build
EOM
}

process_args() {
    while getopts ":c:h" option; do
        case "$option" in
            c) CONTAINER_NAME=$OPTARG;;
            h) usage
               exit 0
               ;;
            *)
               echo "Invalid option '-$OPTARG'"
               usage
               exit 1
               ;;
        esac
    done

    echo ${CONTAINER_NAME}
}

build() {
    case ${CONTAINER_NAME} in
        cnagc-fastchat)
            echo "Build container cnagc-fastchat..."

            docker build \
                -f ${CNAGC_FASTCHAT_ROOT}/Dockerfile.compile \
                --target dev \
                --progress plain \
                -t ${REGISTER}${CONTAINER_NAME}:llm-cpu \
                .

            docker build \
                -f ${CNAGC_FASTCHAT_ROOT}/Dockerfile.release \
                --progress plain \
                --target v2.0.100-cpu \
                -t ${REGISTER}${CONTAINER_NAME}:v2.0.100-cpu \
                .

            docker build \
                -f ${CNAGC_FASTCHAT_ROOT}/Dockerfile.release \
                --progress plain \
                --target v2.0.110-xpu \
                -t ${REGISTER}${CONTAINER_NAME}:v2.0.110-xpu \
                .
            ;;
        cnagc-fastchat-k8s)
            echo "Build container cnagc-fastchat-k8s..."
            docker build \
                -f ${CNAGC_FASTCHAT_K8S_ROOT}/Dockerfile \
                --progress plain \
                -t ${REGISTER}${CONTAINER_NAME} \
                .
            ;;
        *)
            echo "Invalid container name ${CONTAINER_NAME}"
            exit 1
            ;;
    esac
}

process_args "$@"
build
