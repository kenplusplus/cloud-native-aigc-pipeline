#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to log messages with timestamp
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Environment Variables with Default Values
DEPLOY_TYPE=${DEPLOY_TYPE:-default}
FASTCHAT_ROOT=${FASTCHAT_ROOT:-/fastchat}
CONTROLLER_SVC=${CONTROLLER_SVC:-fastchat-controller}
CONTROLLER_PORT=${CONTROLLER_PORT:-21001}
UI_PORT=${UI_PORT:-9000}
MODEL_WORKER_SVC=${MODEL_WORKER_SVC:-fastchat-model-worker}
MODEL_WORKER_PORT=${MODEL_WORKER_PORT:-21002}
OPENAI_API_PORT=${OPENAI_API_PORT:-8000}

cd "${FASTCHAT_ROOT}"

case "$DEPLOY_TYPE" in
    "controller")
        log "Starting controller on port ${CONTROLLER_PORT}..."
        /opt/conda/bin/python -m fastchat.serve.controller --host 0.0.0.0 --port "${CONTROLLER_PORT}"
        ;;
    "ui")
        log "Starting UI on port ${UI_PORT}..."
        /opt/conda/bin/python -m fastchat.serve.gradio_web_server_multi --controller-url http://"${CONTROLLER_SVC}":"${CONTROLLER_PORT}" --host 0.0.0.0 --port "${UI_PORT}" --model-list-mode reload
        ;;
    "model")
        if [ -z "$MODEL_NAME" ]; then
            log "MODEL_NAME not set. Defaulting to 'all'."
            ../models/get_models.sh all
        else
            ../models/get_models.sh "$MODEL_NAME"
        fi
        log "Check ISA from environment: ATEN_CPU_CAPABILITY=${CPU_ISA}"
        log "Check ISA from pytorch:"
        /opt/conda/bin/python -c 'import intel_extension_for_pytorch._C as core;print(core._get_current_isa_level())'

        export LD_PRELOAD="/opt/conda/lib/libiomp5.so:/usr/lib/x86_64-linux-gnu/libtcmalloc.so"
        MODEL_PATH="$MODEL_NAME"  # Adjust this path based on where the get_model script downloads the models
        log "Starting model worker on port ${MODEL_WORKER_PORT}..."
	/opt/conda/bin/python -m fastchat.serve.model_worker --model-path "${MODEL_PATH}" --model-names "${MODEL_NAME}-${CPU_ISA}" --worker-address http://"${MODEL_WORKER_SVC}":"${MODEL_WORKER_PORT}" --controller-address http://"${CONTROLLER_SVC}":"${CONTROLLER_PORT}" --host 0.0.0.0 --port "${MODEL_WORKER_PORT}" --device cpu
        ;;
    "openaiapi")
        log "Starting OpenAI API server on port ${OPENAI_API_PORT}..."
        /opt/conda/bin/python -m fastchat.serve.openai_api_server --controller-address http://"${CONTROLLER_SVC}":"${CONTROLLER_PORT}" --host 0.0.0.0 --port "${OPENAI_API_PORT}"
        ;;
    *)
        log "ERROR: Undefined deployment type '${DEPLOY_TYPE}'. Please specify a valid deployment type."
        exit 1
        ;;
esac

