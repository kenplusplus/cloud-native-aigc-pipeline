#!/bin/bash

CURR_DIR=$(readlink -f "$(dirname "$0")")

# Compile individual component
export CC=${CONDA_PREFIX}/bin/gcc
export CXX=${CONDA_PREFIX}/bin/g++
export LD_PRELOAD=${CONDA_PREFIX}/lib/libstdc++.so

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