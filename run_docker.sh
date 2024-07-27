#!/bin/bash

# Function: log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function: check command return status
utils_check_ret() {
    if [ $1 -eq 0 ]; then
        log "[INFO] $2 done!"
    else
        log "[ERR] Failed on $2!"
        exit -1
    fi
}

# Run container

DOCKER_TAG=imx6_yoctocontainer

if [ -z "$(docker images -q ${DOCKER_TAG})" ]; then
    echo "[INFO] Docker image '${DOCKER_TAG}' not found. Please build_docker.sh first!";
else
    echo "[INFO] Docker image '${DOCKER_TAG}' found.";
    docker run \
        --cap-add NET_ADMIN \
        --hostname buildserver \
        -it \
        -v ${PWD}/bsp:/home/build/bsp \
        -v ${PWD}/secure_boot:/home/build/secure_boot \
        -v ${PWD}/docker_entrypoint.sh:/home/build/docker_entrypoint.sh \
        -w /home/build \
        ${DOCKER_TAG} /bin/bash -c "/home/build/docker_entrypoint.sh"
fi