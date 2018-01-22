#!/usr/bin/env bash

##########################################
#
#   Starts a new DynamoDB Docker
#   based on image: https://hub.docker.com/r/dwmkerr/dynamodb/
#
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
#          --dyno_tbl_name: dynamoDB table name
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
    --dyno_tbl_name=*)
      dyno_tbl_name="${1#*=}"
      ;;
    --port=*)
      port="${1#*=}"
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
PORT=${port:-8765}
DYNO_TABLE=${dyno_tbl_name:-raw-events}

bash stopDocker.sh --name=${DOCKER_NAME} --s=${SUDO} || echo "No docker container called '${DOCKER_NAME}' found running."

echo "Starting $DOCKER_NAME container"
${SUDO} docker run -d --name ${DOCKER_NAME} \
    -p ${PORT}:8000 \
    --net=mycompany \
    dwmkerr/dynamodb

echo "List of current available dockers..."
${SUDO} docker ps

sleep 3
echo "Checking that dyno docker is running without problems ..."

#echo "DynamoDB Docker is setup to be ephemeral storage, thus we always need to create a new table when we boot it..."
#aws dynamodb create-table \
#    --table-name ${DYNO_TABLE} \
#    --attribute-definitions \
#        AttributeName=EventHash,AttributeType=S AttributeName=DatetimePosted,AttributeType=S \
#    --key-schema AttributeName=EventHash,KeyType=HASH AttributeName=DatetimePosted,KeyType=RANGE \
#    --provisioned-throughput ReadCapacityUnits=200,WriteCapacityUnits=200 \
#    --endpoint http://localhost:${PORT}

echo "Current DynamoDB tables:"
aws dynamodb list-tables --endpoint http://localhost:${PORT}