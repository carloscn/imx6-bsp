#!/bin/bash

DOCKER_TAG=imx6_yoctocontainer

if [ -z "$(docker images -q ${DOCKER_TAG})" ]; then
    echo "[INFO] Docker image '${DOCKER_TAG}' not found. Building Docker image."
    docker build -t ${DOCKER_TAG} .
else
    echo "[INFO] Docker image '${DOCKER_TAG}' already exists. Skipping build."
fi
