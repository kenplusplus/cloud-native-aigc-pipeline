
# Build Intel Extension For Pytorch

- Build

```
docker build -f Dockerfile.compile -t gar-registry.caas.intel.com/cpio/intel-extension-for-pytorch:llm --progress plain .
docker push gar-registry.caas.intel.com/cpio/intel-extension-for-pytorch:llm
```

- Use

```
docker pull gar-registry.caas.intel.com/cpio/intel-extension-for-pytorch:llm
```