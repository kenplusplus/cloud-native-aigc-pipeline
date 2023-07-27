#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")
ISA_TYPE="avx2"
MODEL_PATH=""

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
  -h                Show this help
EOM
}

process_args() {
    while getopts ":i:m:h" option; do
        case "$option" in
            i) ISA_TYPE=$OPTARG;;
            m) MODEL_PATH=$OPTARG;;
            h) usage
               exit 0
               ;;
            *)
               error "Invalid option '-$OPTARG'"
               ;;
        esac
    done

    case "$ISA_TYPE" in
        avx2)
            export ATEN_CPU_CAPABILITY=avx2
            ;;
        avx512)
            export ATEN_CPU_CAPABILITY=avx512
            ;;
        amx)
            export ATEN_CPU_CAPABILITY=amx
            ;;
        *)
            error "Invalid ISA type: ${ISA_TYPE}"
            ;;
    esac

    if [[ -z ${MODEL_PATH} ]]; then
        error "Please specify the model path via -m"
    else
        if [[ ! -d ${MODEL_PATH} ]]; then
            error "Model path ${MODEL_PATH} does not exist."
        fi
    fi

    info "Check ISA type:"
    python -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'
}

if [[ ! -d ${CURR_DIR}/venv ]]; then
    ${CURR_DIR}/setup.sh
fi

source venv/bin/activate

process_args "$@"

export PYTHONPATH=%PYTHONPATH:${CURR_DIR}/fastchat/
python3 -m fastchat.serve.cli --model-path $MODEL_PATH --device cpu
