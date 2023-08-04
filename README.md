# Cloud Native AI-Generated Content (CNAGC)

This project is to bring AIGC to Kubernetes via cloud native stateless design.

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
