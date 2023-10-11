#!/bin/bash

# set -x

# Download and install cri-resource-manager
echo "Download the cri-rm package for ubuntu/debian"
CRIRM_VERSION=`curl -s "https://api.github.com/repos/intel/cri-resource-manager/releases/latest" | \
               jq .tag_name | tr -d '"v'`
source /etc/os-release
pkg=cri-resource-manager_${CRIRM_VERSION}_${ID}-${VERSION_ID}_amd64.deb; curl -LO https://github.com/intel/cri-resource-manager/releases/download/v${CRIRM_VERSION}/${pkg}; sudo dpkg -i ${pkg}; rm ${pkg}

# Start the cri-rm service on host
echo "Configure the cri-rm service on host and start it"
cp /etc/cri-resmgr/fallback.cfg.sample /etc/cri-resmgr/fallback.cfg
sudo systemctl enable cri-resource-manager && sudo systemctl start cri-resource-manager

# Configure the kubelet args
echo "Configure the kubelet args to use cri-rm as the container runtime endpoint"
#sudo echo "KUBELET_KUBEADM_ARGS=\"--container-runtime=remote --container-runtime-endpoint=unix:///var/run/cri-resmgr/cri-resmgr.sock --pod-infra-container-image=registry.k8s.io/pause:3.8\"" > /var/lib/kubelet/kubeadm-flags.env
echo "KUBELET_KUBEADM_ARGS=\"--container-runtime=remote --container-runtime-endpoint=unix:///var/run/cri-resmgr/cri-resmgr.sock --pod-infra-container-image=registry.k8s.io/pause:3.8\"" | sudo tee -a /var/lib/kubelet/kubeadm-flags.env
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# Install cri resource manager node agent for dynamic configuration update
echo "Create cri resource manager CRD and node agent"
sudo crictl pull intel/cri-resmgr-agent:v0.7.2
kubectl apply -f ./agent/.

# Apply the balloons policy
kubectl apply -f ./policy/balloons.yaml

# Reload cri-rm
cri-resmgr --reset-policy
sudo systemctl restart cri-resource-manager
