#!/bin/bash

REGISTER="gar-registry.caas.intel.com/cpio/"
CONTAINER_NAME="cloud-native-aigc"

docker build \
    -f ./ipex-build/Dockerfile.compile \
    --target dev \
    --progress plain \
    -t ${REGISTER}${CONTAINER_NAME} \
    .
