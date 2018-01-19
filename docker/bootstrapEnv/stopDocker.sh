#!/usr/bin/env bash

# Generic Stop Script

set -e

while [ $# -gt 0 ]; do
  case "$1" in
    --s=*)
      s="${1#*=}"
      ;;
    *)
      printf "***************************\n"
      printf "* Error: Invalid argument.*\n"
      printf "***************************\n"
      exit 1
  esac
  shift
done

SUDO=${s}

ROOT_DIR=$(dirname "${PWD}")

KINESIS_DIR=$ROOT_DIR/kinesis
POSTGRES_DIR=$ROOT_DIR/postgres
S3_DIR=$ROOT_DIR/s3
DYNO_DIR=$ROOT_DIR/dynamodb
MR_DIR=$ROOT_DIR/mediarithmics-api


function stopDocker(){
    DOCKER_NAME=$1
    echo "stopping docker: ${DOCKER_NAME}"
    bash stopDocker.sh --name=$DOCKER_NAME --s=$SUDO || echo "WARNING: No docker container called '${DOCKER_NAME}' found running."
}

function stopKinesisDocker(){
    printf "\n\n##### Stopping Kinesis Docker.. #####\n"
    cd $KINESIS_DIR
    stopDocker mycompany_kinesis
    printf "\n##### Finished stopping Kinesis Docker. #####\n"
}

function stopPostgresDocker(){
    printf "\n\n##### Stopping Postgres Docker.. #####\n"
    cd $POSTGRES_DIR
    stopDocker mycompany_postgres
    printf "\n\n##### Finished stopping Postgres Docker. #####\n"
}

function stopS3Docker(){
    printf "\n\n##### Stopping S3 Docker.. #####\n"
    cd $S3_DIR
    stopDocker mycompany_s3server
    printf "\n##### Finished stopping S3 Docker. #####\n"
}

function stopDynoDocker(){
    printf "\n\n##### Stopping DynamoDB Docker.. #####\n"
    cd $DYNO_DIR
    stopDocker mycompany_s3server
    printf "\n##### Finished stopping DynamoDB Docker. #####\n"
}

function stopMRDocker(){
    printf "\n\n##### Stopping Mediarithmics Mock API Docker.. #####\n"
    cd $DYNO_DIR
    stopDocker mycompany_s3server
    printf "\n##### Finished stopping Mediarithmics Mock API Docker. #####\n"
}

function welcome(){
    printf "\n##### Starting script to stop all running docker containers ... #####\n"
}

function bye(){
    printf "\n\n##### Finished stopping Docker environment. Bye! #####\n"
}

welcome
stopKinesisDocker
stopPostgresDocker
stopS3Docker
stopDynoDocker
stopMRDocker