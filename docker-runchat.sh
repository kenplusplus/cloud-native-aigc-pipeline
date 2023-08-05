#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")
ISA_TYPE="avx2"
MODEL_PATH=""
REGISTER="gar-registry.caas.intel.com/cpio/"
CONTAINER_NAME="cnagc-fastchat"
IS_DEBUG=false
TAG="2.0.110-xpu"

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
  -t <tag>          [llm-cpu|2.0.110-xpu], default is 2.0.110-xpu
  -d                Debug mode
  -h                Show this help
EOM
}

process_args() {
    while getopts ":i:m:hd" option; do
        case "$option" in
            i) ISA_TYPE=$OPTARG;;
            m) MODEL_PATH=$OPTARG;;
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

echo "Start run chat in docker ..."

process_args "$@"

if [[ $IS_DEBUG == true ]]; then
    docker run \
        -it \
        -v .:/cse-cnagc \
        -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
        -v ./fastchat:/fastchat \
        -v $MODEL_PATH:/model/ \
        -v ./start-chat.sh:/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}:${TAG} \
        /bin/bash
else
    docker run \
        -it \
        -v .:/cse-cnagc \
        -e ATEN_CPU_CAPABILITY=${ISA_TYPE} \
        -v ./fastchat:/fastchat \
        -v $MODEL_PATH:/model/ \
        -v ./start-chat.sh:/start-chat.sh \
        ${REGISTER}${CONTAINER_NAME}${TAG} \
        /start-chat.sh -m /model/ -r /fastchat
fi


