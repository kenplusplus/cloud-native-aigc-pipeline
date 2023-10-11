# Note

## Install CRI Resource Manager to your cluster

```bash
# This script will install the CRI-RM and apply the balloon policy with some pre-configuration on SPR
bash install_cri_rm.sh
```

## Patch your workload and assign a balloon for them

```bash
export NS=<workload_namespace>
# Here, we support `common`, `compute`, `cache`, `io` balloon types
bash patch.sh <deployment_name> <balloon_type>
```
