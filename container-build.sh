#!/bin/bash

REGISTER="gar-registry.caas.intel.com/cpio/"
CONTAINER_NAME="cnagc-fastchat"

docker build \
    -f ./container/Dockerfile.compile \
    --target dev \
    --progress plain \
    -t ${REGISTER}${CONTAINER_NAME}:llm-cpu \
    .

docker build \
    -f ./container/Dockerfile.release \
    --progress plain \
    -t ${REGISTER}${CONTAINER_NAME}:2.0.110-xpu \
    .