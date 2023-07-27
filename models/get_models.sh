#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")

MODEL_DOWNLOAD_URL="http://css-devops.sh.intel.com/download/aigc/models/"

MODELS=("fastchat-t5-3b-v1.0" "vicuna-7b-v1.3" )

for model_name in ${MODELS[@]}; do
    if [[ ! -f ${CURR_DIR}/${model_name}.tar.gz ]]; then
        wget -O ${CURR_DIR}/${model_name}.tar.gz ${MODEL_DOWNLOAD_URL}/${model_name}.tar.gz
    fi

    if [[ ! -d ${CURR_DIR}/${model_name} ]]; then
        ${CURR_DIR}/../tools/tarx -d ${CURR_DIR}/${model_name}.tar.gz
        echo "Successful decompress the ${model_name}.tar.gz ==> ${CURR_DIR}/${model_name}..."
    fi

    echo "Model ${model_name} is ready at ${CURR_DIR}/${model_name}"
done