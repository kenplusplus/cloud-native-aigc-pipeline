from gar-registry.caas.intel.com/cpio/cnagc-fastchat:v2.0.100-cpu

COPY ./container/cnagc-fastchat-k8s/entrypoint.sh .
COPY ./models/get_models.sh /models/

ADD ./tools /tools

RUN chmod +x /models/get_models.sh ./entrypoint.sh
