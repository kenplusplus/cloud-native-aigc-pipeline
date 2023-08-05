#!/bin/bash

FASTCHAT_ROOT=""
MODEL_PATH=""

usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...
  -m <model path>       Directory name of model path
  -r <fastchat root>    Root directory of fastchat
  -h                    Show this help
EOM
}

process_args() {
    while getopts ":r:m:h" option; do
        case "$option" in
            m) MODEL_PATH=$OPTARG;;
            r) FASTCHAT_ROOT=$OPTARG;;
            h) usage
               exit 0
               ;;
            *)
               error "Invalid option '-$OPTARG'"
               ;;
        esac
    done

    if [[ -z ${FASTCHAT_ROOT} ]]; then
        error "Please specify the fastchat root path via -m"
    else
        FASTCHAT_ROOT=$(readlink -f ${FASTCHAT_ROOT})
        echo "FASTCHAT_ROOT: ${FASTCHAT_ROOT}..."

        if [[ ! -d ${FASTCHAT_ROOT} ]]; then
            error "Fastchat root path ${FASTCHAT_ROOT} does not exist."
        fi
    fi

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

echo "Start fastchat ..."
process_args "$@"

echo "Check ISA from envrionment: ATEN_CPU_CAPABILITY=${ATEN_CPU_CAPABILITY}"
echo "Check ISA from pytorch:"
python -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'

#export OMP_NUM_THREADS=1
#export KMP_BLOCKTIME=1
export KMP_HW_SUBSET=1T

cd ${FASTCHAT_ROOT}
python3 -m fastchat.serve.cli --model-path ${MODEL_PATH} --device cpu
