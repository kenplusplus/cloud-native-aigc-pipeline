#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")

REGISTER="bluewish/"
CONTAINER_NAME="cnagc-fastchat"
CNAGC_FASTCHAT_ROOT=${CURR_DIR}/container/cnagc-fastchat
CNAGC_FASTCHAT_K8S_ROOT=${CURR_DIR}/container/cnagc-fastchat-k8s
TAG="v2.2.0-cpu"

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

            cd ${CURR_DIR}/intel-extension-for-pytorch/
            git checkout v2.2.0+cpu
            git submodule sync
            git submodule update --init --recursive
            DOCKER_BUILDKIT=1 docker build -f examples/cpu/inference/python/llm/Dockerfile -t ipex-llm:2.2.0 .

            cd ${CURR_DIR}
            docker build \
                -f ${CNAGC_FASTCHAT_ROOT}/Dockerfile.release \
                --progress plain \
                -t ${REGISTER}${CONTAINER_NAME}:${TAG} \
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
