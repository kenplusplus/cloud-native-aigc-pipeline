from gar-registry.caas.intel.com/cpio/cnagc-fastchat:v2.0.101-cpu

RUN /opt/conda/bin/python -m pip install plotly

COPY ./container/cnagc-fastchat-k8s/entrypoint.sh .
COPY ./models/get_models.sh /models/

ADD ./tools /tools

RUN chmod +x /models/get_models.sh ./entrypoint.sh
