#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")
ISA_TYPE="avx2"
MODEL_PATH=""
REGISTER="bluewish/"
CONTAINER_NAME="cnagc-fastchat"
IS_DEBUG=false
TAG="v2.2.0-cpu"
RUNTYPE="cli"

CONTROLLER_SVC=${CONTROLLER_SVC:-localhost}
CONTROLLER_PORT=${CONTROLLER_PORT:-21001}
UI_PORT=${UI_PORT:-9000}
MODEL_WORKER_SVC=${MODEL_WORKER_SVC:-localhost}
MODEL_WORKER_PORT=${MODEL_WORKER_PORT:-21002}
OPENAI_API_PORT=${OPENAI_API_PORT:-8000}

info() {
    echo -e "\e[1;33mINFO: $*\e[0;0m"
}

ok() {
    echo -e "\e[1;32mSUCCESS: $*\e[0;0m"
}

error() {
    echo -e "\e[1;31mERROR: $*\e[0;0m"
    exit 1
}

warn() {
    echo -e "\e[1;33mWARN: $*\e[0;0m"
}

usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...
  -i <ISA type>                             [avx2|avx512|amx]
  -m <model path>                           Directory name of model path
  -t [cli|controller|apiserver|ui|model]   Run type for docker based fastchat
  -p <Controller Port>                      Controller port, default is 21000
  -u <UI Port>                              UI port, default is 9000
  -d                                        Interactive debug mode
  -r
  -h                Show this help
EOM
}

process_args() {
    while getopts ":i:m:p:t:c:u:hd" option; do
        case "$option" in
            i) ISA_TYPE=$OPTARG;;
            m) MODEL_PATH=$OPTARG;;
            t) RUNTYPE=$OPTARG;;
            p) CONTROLLER_PORT=$OPTARG;;
            u) UI_PORT=$OPTARG;;
            d) IS_DEBUG=true;;
            c) CONTROLLER_URL=$OPTARG;;
            h) usage
               exit 0
               ;;
            *)
               error "Invalid option '-$OPTARG'"
               ;;
        esac
    done
}

check_model_path() {
    if [[ -z ${MODEL_PATH} ]]; then
        error "Please specify the model path via -m"
    else
        MODEL_PATH=$(readlink -f ${MODEL_PATH})
        echo "MODEL_PATH: ${MODEL_PATH}..."

        if [[ ! -d ${MODEL_PATH} ]]; then
            error "Model path ${MODEL_PATH} does not exist."
        fi

    fi
}

run_cli() {
    echo "Start run chat CLI mode in docker ..."

    check_model_path
    if [[ $IS_DEBUG == true ]]; then
        docker run \
            -it \
            -v .:/cse-cnagc \
            -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
            -v ./fastchat:/home/ubuntu/fastchat \
            -v $MODEL_PATH:/home/ubuntu/model/ \
            -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
            ${REGISTER}${CONTAINER_NAME}:${TAG} \
            /bin/bash
    else
        docker run \
            -it \
            -v .:/cse-cnagc \
            -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
            -v ./fastchat:/home/ubuntu/fastchat \
            -v $MODEL_PATH:/home/ubuntu/model/ \
            -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
            ${REGISTER}${CONTAINER_NAME}:${TAG} \
            /home/ubuntu/start-chat.sh -m /home/ubuntu/model/ -r /home/ubuntu/fastchat
    fi
}

run_controller() {
    info "Starting controller on port ${CONTROLLER_PORT}..."
    docker run \
        -it \
        -v .:/cse-cnagc \
        -p ${CONTROLLER_PORT}:${CONTROLLER_PORT} \
        -e CONTROLLER_PORT=${CONTROLLER_PORT} \
        -v ./fastchat:/home/ubuntu/fastchat \
        -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}:${TAG} \
        /home/ubuntu/start-chat.sh -r /home/ubuntu/fastchat -t controller
}

run_ui() {
    info "Starting UI on port ${UI_PORT}..."
    if [ ${CONTROLLER_SVC} = "localhost" ]; then
        error "Env CONTROLLER_SVC should not be localhost, it could be host's IP address or DNS name."
    fi

    docker run \
        -it \
        -v .:/cse-cnagc \
        -p ${UI_PORT}:${UI_PORT} \
        -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
        -e CONTROLLER_SVC=${CONTROLLER_SVC} \
        -e CONTROLLER_PORT=${CONTROLLER_PORT} \
        -e UI_PORT=${UI_PORT} \
        -v ./fastchat:/home/ubuntu/fastchat \
        -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}:${TAG} \
        /home/ubuntu/start-chat.sh -r /home/ubuntu/fastchat -t ui
}

run_model() {
    info "Starting model on port ${MODEL_WORKER_PORT}..."

    if [ -z "${MODEL_PATH}" ]; then
        error "Please specify MODEL_PATH via -m"
    fi

    if [ -z "${MODEL_NAME}" ]; then
        MODEL_NAME=$(basename ${MODEL_PATH})
    fi

    if [ ${CONTROLLER_SVC} = "localhost" ]; then
        error "Env CONTROLLER_SVC should not be localhost, it could be host's IP address or DNS name."
    fi

    if [ ${MODEL_WORKER_SVC} = "localhost" ]; then
        error "Env MODEL_WORKER_SVC should not be localhost, it could be host's IP address or DNS name."
    fi

    docker run \
        -it \
        -v .:/cse-cnagc \
        -v ${MODEL_PATH}:/home/ubuntu/model \
        -p ${MODEL_WORKER_PORT}:${MODEL_WORKER_PORT} \
        -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
        -e CPU_ISA=${ISA_TYPE} \
        -e MODEL_NAME=${MODEL_NAME} \
        -e MODEL_WORKER_SVC=${MODEL_WORKER_SVC} \
        -e MODEL_WORKER_PORT=${MODEL_WORKER_PORT} \
        -e CONTROLLER_SVC=${CONTROLLER_SVC} \
        -e CONTROLLER_PORT=${CONTROLLER_PORT} \
        -v ./fastchat:/home/ubuntu/fastchat \
        -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}:${TAG} \
        /home/ubuntu/start-chat.sh -r /home/ubuntu/fastchat -t model -m /home/ubuntu/model/
}

run_openai_apiserver() {
    if [ ${CONTROLLER_SVC} = "localhost" ]; then
        error "Env CONTROLLER_SVC should not be localhost, it could be host's IP address or DNS name."
    fi

    docker run \
        -it \
        -p ${OPENAI_API_PORT}:${OPENAI_API_PORT} \
        -e CONTROLLER_SVC=${CONTROLLER_SVC} \
        -e CONTROLLER_PORT=${CONTROLLER_PORT} \
        -e OPENAI_API_PORT=${OPENAI_API_PORT} \
        -v ./fastchat:/home/ubuntu/fastchat \
        -v ./container/cnagc-fastchat/start-chat.sh:/home/ubuntu/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}:${TAG} \
        /home/ubuntu/start-chat.sh -r /home/ubuntu/fastchat -t apiserver
}

process_args "$@"

echo "======================================="
echo " Model        : ${MODEL_PATH}"
echo " Container    : ${REGISTER}${CONTAINER_NAME}:${TAG}"
echo " ISA          : ${ISA_TYPE}"
echo " Run Type     : ${RUNTYPE}"
echo " Debug        : ${IS_DEBUG}"
echo "======================================="

case ${RUNTYPE} in
    "cli")
        run_cli
        ;;
    "controller")
        run_controller
        ;;
    "ui")
        run_ui
        ;;
    "model")
        run_model
        ;;
    "apiserver")
        run_openai_apiserver
        ;;
    *)
        error "Invalid run type ${RUNTYPE}"
        ;;
esac
