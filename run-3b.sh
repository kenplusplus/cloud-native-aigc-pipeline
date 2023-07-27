#!/bin/bash

set -x

CURR_DIR=$(readlink -f "$(dirname "$0")")

if [[ ! -d ${CURR_DIR}/venv ]]; then
    ${CURR_DIR}/setup.sh
fi

# Check current instruction set
python -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'

#
# ATEN_CPU_CAPABILITY=avx2
#

source venv/bin/activate
pushd fastchat
python3 -m fastchat.serve.cli --model-path ../models/fastchat-t5-3b-v1.0/ --device cpu
popd