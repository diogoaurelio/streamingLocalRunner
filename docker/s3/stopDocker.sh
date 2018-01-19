#!/usr/bin/env bash

##########################################
#
#   Stops current running S3 Docker
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
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

SUDO=$s
DOCKER_NAME=${1:-mycompany_s3server}

CWD=$PWD
SCRIPT_DIR=$(dirname "${PWD}")/common
# Generic Stop Script
DOCKER_STOP_SCRIPT=$SCRIPT_DIR/stopDocker.sh

bash $DOCKER_STOP_SCRIPT $DOCKER_NAME $SUDO