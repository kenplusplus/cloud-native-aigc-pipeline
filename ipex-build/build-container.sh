#!/bin/bash

docker build -f Dockerfile.compile --memory=50G -t intel-extension-for-pytorch:llm --progress plain .
