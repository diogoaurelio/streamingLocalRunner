#!/usr/bin/env bash

##########################################
#
#   Stops a new DynamoDB Docker
#   Notes: optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_kinesis"
#          --port: port exported to the outside
#                   by default "8765"
#
#   Usage:
#          bash stopDocker.sh --s=sudo
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
DOCKER_NAME=${name:-mycompany_dynamodb}


CWD=$PWD
SCRIPT_DIR=$(dirname "${PWD}")/common
# Generic Stop Script
DOCKER_STOP_SCRIPT=$SCRIPT_DIR/stopDocker.sh
bash $DOCKER_STOP_SCRIPT $DOCKER_NAME $SUDO