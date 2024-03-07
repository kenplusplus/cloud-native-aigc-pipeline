#!/bin/bash

set -ex

FASTCHAT_ROOT=""
MODEL_PATH=""
RUNTYPE="cli"
PYTHONEXEC="/home/ubuntu/miniconda3/envs/py310/bin/python"
# Please customize below settings via environment variable but not command
# line's argument
ATEN_CPU_CAPABILITY=${ATEN_CPU_CAPABILITY:-AVX2}
CONTROLLER_SVC=${CONTROLLER_SVC:-localhost}
CONTROLLER_PORT=${CONTROLLER_PORT:-21001}
UI_PORT=${UI_PORT:-9000}
MODEL_WORKER_SVC=${MODEL_WORKER_SVC:-localhost}
MODEL_WORKER_PORT=${MODEL_WORKER_PORT:-21002}
CPU_ISA="avx2"

usage() {
    cat << EOM
Usage: $(basename "$0") [OPTION]...
  -m <model path>       Directory name of model path
  -r <fastchat root>    Root directory of fastchat
  -t [cli|controller|apiserver|ui|model] Run type of fastchat
  -h                    Show this help
EOM
}

error() {
    echo "ERROR: $1"
}

process_args() {
    while getopts ":r:m:t:h" option; do
        case "$option" in
            m) MODEL_PATH=$OPTARG;;
            t) RUNTYPE=$OPTARG;;
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
        error "Please specify the fastchat root path via -r"
    else
        FASTCHAT_ROOT=$(readlink -f ${FASTCHAT_ROOT})
        echo "FASTCHAT_ROOT: ${FASTCHAT_ROOT}..."

        if [[ ! -d ${FASTCHAT_ROOT} ]]; then
            error "Fastchat root path ${FASTCHAT_ROOT} does not exist."
        fi
    fi


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
    echo "Start fastchat CLI ..."
    check_model_path
    cd ${FASTCHAT_ROOT}
    ${PYTHONEXEC} -m fastchat.serve.cli --model-path ${MODEL_PATH} --device cpu --debug
}

run_controller() {
    echo "Start fastchat controller ..."
    cd ${FASTCHAT_ROOT}
    ${PYTHONEXEC} -m fastchat.serve.controller \
        --host 0.0.0.0 --port "${CONTROLLER_PORT}"
}

run_ui() {
    echo "Start fastchat UI..."
    cd ${FASTCHAT_ROOT}
    ${PYTHONEXEC} -m fastchat.serve.gradio_web_server_multi \
        --controller-url http://"${CONTROLLER_SVC}":"${CONTROLLER_PORT}" \
        --host 0.0.0.0 --port "${UI_PORT}" \
        --model-list-mode reload
}

run_model() {
    echo "Start fastchat model..."

    echo "Check ISA from envrionment: ATEN_CPU_CAPABILITY=${ATEN_CPU_CAPABILITY}"
    echo "Check ISA from pytorch:"
    ${PYTHONEXEC} -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'

    ${PYTHONEXEC} -m fastchat.serve.model_worker \
        --model-path "${MODEL_PATH}" \
        --model-names "${MODEL_NAME}-${CPU_ISA}" \
        --worker-address http://"${MODEL_WORKER_SVC}":"${MODEL_WORKER_PORT}" \
        --controller-address http://"${CONTROLLER_SVC}":"${CONTROLLER_PORT}" \
        --host 0.0.0.0 --port "${MODEL_WORKER_PORT}" \
        --device cpu
}

process_args "$@"


#export OMP_NUM_THREADS=1
#export KMP_BLOCKTIME=1
#export KMP_HW_SUBSET=1T
#export GOMP_CPU_AFFINITY="0-3"
#export OMP_PROC_BIND=CLOSE
#export OMP_SCHEDULE=STATIC
#export LD_PRELOAD=/opt/conda/lib/libiomp5.so:/usr/lib/x86_64-linux-gnu/libtcmalloc.so

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
    *)
        error "Invalid run type ${RUNTYPE}"
        ;;
esac
