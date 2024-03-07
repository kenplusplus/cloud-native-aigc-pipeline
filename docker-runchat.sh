#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")
ISA_TYPE="avx2"
MODEL_PATH=""
REGISTER="bluewish/"
CONTAINER_NAME="cnagc-fastchat"
IS_DEBUG=false
TAG="v2.2.0-cpu"
RUNTYPE="cli"

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
  -i <ISA type>     [avx2|avx512|amx]
  -m <model path>   Directory name of model path
  -t [cli|controller|worker] Run t
  -d                Interactive debug mode
  -r
  -h                Show this help
EOM
}

process_args() {
    while getopts ":i:m:t:hd" option; do
        case "$option" in
            i) ISA_TYPE=$OPTARG;;
            m) MODEL_PATH=$OPTARG;;
            t) RUNTYPE=$OPTARG;;
            d) IS_DEBUG=true;;
            h) usage
               exit 0
               ;;
            *)
               error "Invalid option '-$OPTARG'"
               ;;
        esac
    done

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

process_args "$@"

echo "======================================="
echo " Model        : $MODEL_PATH"
echo " Container    : ${REGISTER}${CONTAINER_NAME}:${TAG}"
echo " ISA          : ${ISA_TYPE}"
echo " Run Type     : ${RUNTYPE}"
echo " Debug        : ${IS_DEBUG}"
echo "======================================="


case ${RUNTYPE} in
    "cli")
        run_cli
        ;;
    *)
        error "Invalid run type ${RUNTYPE}"
        ;;
esac



