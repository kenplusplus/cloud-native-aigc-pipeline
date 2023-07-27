#!/bin/bash

set -x

CURR_DIR=$(readlink -f "$(dirname "$0")")

if [[ ! -d ${CURR_DIR}/venv ]]; then
    ${CURR_DIR}/setup.sh
fi

#export ATEN_CPU_CAPABILITY=avx512
export ATEN_CPU_CAPABILITY=amx
# Check current instruction set
python -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'

#
# ATEN_CPU_CAPABILITY=avx2
#

source venv/bin/activate
export PYTHONPATH=%PYTHONPATH:${CURR_DIR}/fastchat/
python3 -m fastchat.serve.cli --model-path $1 --device cpu
