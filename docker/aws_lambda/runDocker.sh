#!/usr/bin/env bash

##########################################
#
#   Starts a new Docker that has a simular env to the one where
#   Lambda functions will be running. It is thus useful for testing
#   packages conflicts, for example
#   More info: https://github.com/lambci/docker-lambda
#
#   Notes: optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_lambda"
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
    --build=*)
      build="${1#*=}"
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
DOCKER_NAME=${name:-mycompany_lambda}

DOCKER_DIR=$(dirname "${PWD}")
ROOT_DIR=$(dirname "${DOCKER_DIR}")
BUILD=${build:-true}
IMAGE_NAME="kinesis-java8-lambda"

if [ $BUILD == "true" ]; then
    echo "Build is set to true. Building docker container"
    ${SUDO} docker build --rm -t ${IMAGE_NAME}:latest .
else
    echo "Build is set to false. Skipping docker image build step"
fi


bash stopDocker.sh --name=${DOCKER_NAME} --s=${SUDO} || echo "No docker container called '${DOCKER_NAME}' found running."

echo "Starting $DOCKER_NAME container"

${SUDO} docker run -d -t --name ${DOCKER_NAME} \
    -v ${ROOT_DIR}:/var/task \
    --net=mycompany \
    -e DATABASE_HOST=mycompany_postgres \
    -e DATABASE_PORT=5432 \
    -e DYNAMODB_ENDPOINT=http://mycompany_dynamo:8000 \
    -e AWS_CBOR_DISABLE=true \
    ${IMAGE_NAME}:latest