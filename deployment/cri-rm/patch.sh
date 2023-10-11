#!/bin/bash

if [ ! -z "$1" ]
then
  if [ ! -z "$2" ]
  then
    TYPE="$2"
    kubectl patch -n "${NS}" deployments.apps "$1" -p '{"spec": {"template":{"metadata":{"annotations":{"balloon.balloons.cri-resource-manager.intel.com": "'"$TYPE"'" }}}}}'
  fi
fi
