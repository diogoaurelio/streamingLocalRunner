#!/usr/bin/env bash

##########################################
#
#   Stops current running Postgres Docker
#   Notes:
#           optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_postgres"
#          --port: postgres port exported to the outside
#                   by default "15432"
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
DOCKER_NAME=${name:-mycompany_postgres}


CWD=$PWD
SCRIPT_DIR=$(dirname "${PWD}")/common
# Generic Stop Script
DOCKER_STOP_SCRIPT=$SCRIPT_DIR/stopDocker.sh

bash $DOCKER_STOP_SCRIPT $DOCKER_NAME $SUDO