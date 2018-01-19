#!/usr/bin/env bash

##########################################
#
#   Starts a new kinesis Docker
#   Notes: optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_kinesis"
#          --kport: kinesis port exported to the outside
#                   by default "4567"
#
#   Usage:
#          bash runDocker.sh --s=sudo
#
#
##########################################


while [ $# -gt 0 ]; do
  case "$1" in
    --s=*)
      s="${1#*=}"
      ;;
    --name=*)
      name="${1#*=}"
      ;;
    --aws_profile=*)
      aws_profile="${1#*=}"
      ;;
    --kport=*)
      kport="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

SUDO=$s
DOCKER_NAME=${name:-mycompany_kinesis}
KINESIS_PORT=${kport:-4567}

bash stopDocker.sh --name=${DOCKER_NAME} --s=${SUDO} || echo "No docker container called '${DOCKER_NAME}' found running."

echo "Starting $DOCKER_NAME container"
${SUDO} docker run -d --name ${DOCKER_NAME} \
    -p ${KINESIS_PORT}:4567 \
    --net=mycompany \
    vsouza/kinesis-local \
    --port ${KINESIS_PORT}


