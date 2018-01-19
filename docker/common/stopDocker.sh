#!/usr/bin/env bash

DOCKER_NAME=${1}
SUDO=${2}

$SUDO docker stop $DOCKER_NAME
rm -rf $PWD/_tmp
printf "\n\nStopping docker container: '$DOCKER_NAME'\n"
$SUDO docker rm -f $DOCKER_NAME