#!/usr/bin/env bash

##########################################################
#
# Starts the whole Docker environment up
#
# Example usage: bash runDocker.sh local sudo
#
##########################################################


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

DOCKER_DIR=$(dirname "${PWD}")
ROOT_DIR=$(dirname "${DOCKER_DIR}")
KINESIS_DIR=$DOCKER_DIR/kinesis
POSTGRES_DIR=$DOCKER_DIR/postgres
S3_DIR=$DOCKER_DIR/s3
DYNO_DIR=$DOCKER_DIR/dynamodb
MR_DIR=$DOCKER_DIR/mediarithmics-api
COMMON_DIR=$DOCKER_DIR/common


function runKinesisDocker(){
    printf "\n\n##### Launching Kinesis Docker.. #####\n"
    cd $KINESIS_DIR
    bash runDocker.sh --s=$SUDO
    printf "\n##### Finished launching Kinesis Docker. #####\n"
}

function runPostgresDocker(){
    printf "\n\n##### Launching Postgres Docker.. #####\n"
    cd $POSTGRES_DIR
    bash runDocker.sh --s=$SUDO
    printf "\n\n##### Finished launching Postgres Docker. #####\n"
}

function runS3Docker(){
    printf "\n\n##### Launching S3 Docker.. #####\n"
    cd $S3_DIR
    bash runDocker.sh --s=${SUDO}
    printf "\n##### Finished launching S3 Docker. #####\n"
}

function runDynoDocker(){
    printf "\n\n##### Launching DynamoDB Docker.. #####\n"
    cd $DYNO_DIR
    bash runDocker.sh --s=${SUDO}
    printf "\n##### Finished launching S3 Docker. #####\n"
}

function runMediarithmicsDocker(){
    printf "\n\n##### Launching Mediarithmics Mock API Docker.. #####\n"
    cd $MR_DIR
    bash runDocker.sh --s=${SUDO}
    printf "\n##### Finished launching S3 Docker. #####\n"
}

function setupAwsProfile(){

    AWS_MOCK_KEY="MY_ACCESS_KEY"
    AWS_MOCK_SECRET="MY_SECRET_KEY"
    SETUP_MOCK_S3_SCRIPT=${1:-$COMMON_DIR/setupAwsProfile.sh}
    AWS_REGION=${2:-eu-central-1}
    AWS_PROFILE=${3:-mycompany_local_aws_testing}

    if [ -f $SETUP_MOCK_S3_SCRIPT ]; then
        printf " \nFound mock aws CLI profile setup script. Proceeding to profile creation.\n"
        {
            bash ${SETUP_MOCK_S3_SCRIPT} ${AWS_MOCK_KEY} ${AWS_MOCK_SECRET} ${AWS_REGION} ${AWS_PROFILE}

        } || printf "\nWARNING: Something failed while trying to create new local AWS profile \nDo you have AWS CLI installed?\n"


    else
        printf "ERROR: could NOT find mock S3 aws CLI profile setup script. Halting execution.\n"
        exit 1
    fi
}

function initKinesis(){
    KINESIS_STREAM_NAME=${1:-mycompanyLocalTestStream}
    KINESIS_SHARD_COUNT=${2:-3}
    KINESIS_PORT=${3:-4567}
    AWS_REGION=${4:-eu-central-1}
    AWS_PROFILE=${5:-mycompany_local_aws_testing}

    # import kinesis functions
    source ${COMMON_DIR}/kinesis.sh

    printf "\nCreating new stream in local docker kinesis ...\n"
    createStream ${KINESIS_STREAM_NAME} ${KINESIS_SHARD_COUNT} ${AWS_REGION} ${AWS_PROFILE} ${KINESIS_PORT}

    printf "Validating if shard was successfully created ...\n"

    describeStream ${KINESIS_STREAM_NAME} ${AWS_REGION} ${AWS_PROFILE} ${KINESIS_PORT}

    printf "\nFinished setting up new stream in kinesis\nBye!\n"
}

function welcome(){
    printf "\n##### Starting script to run all containers #####\n"
    bash stopDocker.sh --s=$SUDO || echo "Failed to stop running dockers!"
}

function bye(){
    printf "\n\n##### Finished starting Docker environment. Bye! #####\n"
}

welcome

${SUDO} docker network create mycompany || echo "internal docker network 'mycompany' already exists"

runKinesisDocker
runPostgresDocker
# S3 mock not required for the moment
#runS3Docker
runDynoDocker
runMediarithmicsDocker
setupAwsProfile
initKinesis
bye