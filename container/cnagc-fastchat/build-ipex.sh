#!/bin/bash

set -ex

CURR_DIR=$(readlink -f "$(dirname "$0")")

source ~/.bashrc

VER_IPEX="ken-dev-llm"

LLVM_ROOT=/llvm/release
export PATH=${LLVM_ROOT}/bin:$PATH
export LD_LIBRARY_PATH=${LLVM_ROOT}/lib:$LD_LIBRARY_PATH

MAX_JOBS_VAR=$(($(nproc) / 2 ))
MAX_JOBS_VAR=$((MAX_JOBS_VAR<20?MAX_JOBS_VAR:20))
if [ ! -z "${MAX_JOBS}" ]; then
    MAX_JOBS_VAR=${MAX_JOBS}
fi
export MAX_JOBS=$((MAX_JOBS_VAR<20?MAX_JOBS_VAR:20))

CONDA_PREFIX=/opt/conda/
# Compile individual component
export CC=${CONDA_PREFIX}/bin/gcc
export CXX=${CONDA_PREFIX}/bin/g++
export LD_PRELOAD=${CONDA_PREFIX}/lib/libstdc++.so

# Checkout individual components
if [ ! -d intel-extension-for-pytorch ]; then
    #wget http://css-devops.sh.intel.com/download/mirror/intel-extension-for-pytorch/intel-extension-for-pytorch-2023_07_31.tar.gz
    #tar zxvf intel-extension-for-pytorch-2023_07_31.tar.gz
    #git config --global --add safe.directory "*"
    wget http://css-devops.sh.intel.com/download/mirror/intel-extension-for-pytorch/intel-extension-for-pytorch-2023-08-02.tar.gz
    tar zxvf intel-extension-for-pytorch-2023-08-02.tar.gz
    git config --global --add safe.directory "*"

    #cd intel-extension-for-pytorch
    #git remote add ken https://github.com/intel-sandbox/cse-ipex.git
    #git fetch ken
    #git checkout ${VER_IPEX}
    #git submodule sync
    #git submodule update --init --recursive
    #cd ..
fi


ln -s ${LLVM_ROOT}/bin/llvm-config ${LLVM_ROOT}/bin/llvm-config-13

export USE_LLVM=${LLVM_ROOT}
export LLVM_DIR=${USE_LLVM}/lib/cmake/llvm
export DNNL_GRAPH_BUILD_COMPILER_BACKEND=1
export IPEX_VERSION=2.1.0.dev0+cpu.llm
export IPEX_VERSIONED_BUILD=0
CXXFLAGS_BK=${CXXFLAGS}
export CXXFLAGS="${CXXFLAGS} -D__STDC_FORMAT_MACROS"

cd intel-extension-for-pytorch
python setup.py clean
python setup.py bdist_wheel
export CXXFLAGS=${CXXFLAGS_BK}
unset IPEX_VERSIONED_BUILD
unset IPEX_VERSION
unset DNNL_GRAPH_BUILD_COMPILER_BACKEND
unset LLVM_DIR
unset USE_LLVM
python -m pip install --force-reinstall dist/*.whl
