#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")

MAX_JOBS_VAR=$(nproc)
if [ ! -z "${MAX_JOBS}" ]; then
    MAX_JOBS_VAR=${MAX_JOBS}
fi

conda clean -i

conda install -y gcc==12.3 gxx==12.3 cxx-compiler -c conda-forge

# Checkout required branch/commit and update submodules
if [ ! -d cmake ]; then
    wget http://css-devops.sh.intel.com/download/mirror/llvm-project/cmake-16.0.6.src.tar.xz
    tar -xvf cmake-16.0.6.src.tar.xz
    mv cmake-16.0.6.src cmake
fi

if [ ! -d llvm ]; then
    wget http://css-devops.sh.intel.com/download/mirror/llvm-project/llvm-16.0.6.src.tar.xz
    tar -xvf llvm-16.0.6.src.tar.xz
    mv llvm-16.0.6.src llvm
fi

python -m pip install cmake
#python -m pip install torch==2.1.0.dev20230711+cpu torchvision==0.16.0.dev20230711+cpu torchaudio==2.1.0.dev20230711+cpu --index-url https://download.pytorch.org/whl/nightly/cpu
python -m pip install http://css-devops.sh.intel.com/download/mirror/torch/torch-2.1.0.dev20230730%2Bcpu-cp38-cp38-linux_x86_64.whl
python -m pip install http://css-devops.sh.intel.com/download/mirror/torch/torchvision-0.16.0.dev20230730%2Bcpu-cp38-cp38-linux_x86_64.whl
python -m pip install http://css-devops.sh.intel.com/download/mirror/torch/torchaudio-2.1.0.dev20230730%2Bcpu-cp38-cp38-linux_x86_64.whl
ABI=$(python -c "import torch; print(int(torch._C._GLIBCXX_USE_CXX11_ABI))")

# Compile individual component
export CC=${CONDA_PREFIX}/bin/gcc
export CXX=${CONDA_PREFIX}/bin/g++
export LD_PRELOAD=${CONDA_PREFIX}/lib/libstdc++.so

#  LLVM
LLVM_ROOT="${CURR_DIR}/release"
if [ -d ${LLVM_ROOT} ]; then
    rm -rf ${LLVM_ROOT}
fi
mkdir ${LLVM_ROOT}
if [ -d build ]; then
    rm -rf build
fi
mkdir build
cd build
cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX=${LLVM_ROOT} \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS="-D_GLIBCXX_USE_CXX11_ABI=${ABI}" \
    -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_TESTS=OFF -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF ../llvm/
make install -j $MAX_JOBS