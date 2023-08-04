# Cloud Native AI-Generated Content (CNAGC)

This project is to bring AIGC to Kubernetes via cloud native stateless design.

## Download Models

The pre-trained models were at http://css-devops.sh.intel.com/download/aigc/models/

- To download  model:

```
./models/get_models.sh opt-1.3b-bf16-8b-samples
```

- To download all models:

```
./models/get_models.sh all
```

## Getting Start to Run in Container

1. Build container `gar-registry.caas.intel.com/cpio/cloud-native-aigc`

```
./container-build.sh
```

2. Run cloud native AIGC container with given model

```
./docker-runchat.sh -m models/vicuna-7b-v1.3
```

3. Use different ISA

- use AVX512

```
./docker-runchat.sh -m models/vicuna-7b-v1.3 -i avx512
```

- use AMX

```
./docker-runchat.sh -m models/vicuna-7b-v1.3 -i amx
```


## Getting Start to Run on Kubernetes

TBD
