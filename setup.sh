#!/bin/bash

#CURR_DIR=$(readlink -f "$(dirname "$0")")
CURR_DIR=${PWD}

if [[ ! -d ${CURR_DIR}/venv ]]; then
    mkdir -p ${CURR_DIR}/venv
fi

python3 -m venv ${CURR_DIR}/venv
source ${CURR_DIR}/venv/bin/activate

pushd fastchat
pip3 install --upgrade pip  # enable PEP 660 support
pip3 install -e .
pip3 install intel_extension_for_pytorch # install intel extension for torch
popd
