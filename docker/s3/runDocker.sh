#!/usr/bin/env bash

##########################################
#   TODO: complete this docu
#   Starts a new kinesis Docker
#   Notes: optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --docker_name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_kinesis"
#          --s3_docker_port: s3 port exported to the outside
#                   by default "3333"
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
    --s3_docker_host=*)
      s3_docker_host="${1#*=}"
      ;;
    --s3_docker_port=*)
      s3_docker_port="${1#*=}"
      ;;
    --s3_mock_profile=*)
      s3_mock_profile="${1#*=}"
      ;;
    --mock_bucket=*)
      mock_bucket="${1#*=}"
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
DOCKER_NAME=${name:-mycompany_s3server}
S3_DOCKER_HOST=${s3_docker_host:-127.0.0.1}
S3_DOCKER_PORT=${s3_docker_port:-3333}
S3_MOCK_LOCAL_PROFILE=${s3_mock_profile:-mycompany_local_aws_testing}
MOCK_BUCKET=${mock_bucket:-s3://kinesis-lambda-bucket}

APP_DIR=${PWD}
DOCKER_DIR=$(dirname "${PWD}")
ROOT_DIR=$(dirname "${DOCKER_DIR}")


AWS_MOCK_KEY="MY_ACCESS_KEY"
AWS_MOCK_SECRET="MY_SECRET_KEY"
AWS_REGION="us-east-1"
SETUP_MOCK_S3_SCRIPT=$DOCKER_DIR/common/setupAwsProfile.sh

bash stopDocker.sh --name=$DOCKER_NAME --s=$SUDO || echo "WARNING: No docker container called '${DOCKER_NAME}' found running."

echo "########### Starting S3 Docker: '${DOCKER_NAME}' ########### "


$SUDO docker run -d --name $DOCKER_NAME \
    -p $S3_DOCKER_PORT:8000 \
    -e SCALITY_ACCESS_KEY_ID=$AWS_MOCK_KEY \
    -e SCALITY_SECRET_ACCESS_KEY=$AWS_MOCK_SECRET \
    scality/s3server


if [ -f $SETUP_MOCK_S3_SCRIPT ]; then
    printf " \nFound mock S3 aws CLI profile setup script. Proceeding.\n"

    {

        bash ${SETUP_MOCK_S3_SCRIPT} ${AWS_MOCK_KEY} ${AWS_MOCK_SECRET} ${AWS_REGION} ${S3_MOCK_LOCAL_PROFILE}

        printf "\nAttempting to create new test Bucket(s) ($MOCK_BUCKET) on Docker S3 ... \nNote: it takes some seconds until S3 Docker is completely bootstrapped.\n"
        sleep 45
        aws s3 mb $MOCK_BUCKET --profile $S3_MOCK_LOCAL_PROFILE --endpoint http://$S3_DOCKER_HOST:$S3_DOCKER_PORT \
            && printf "\nDone, successfully created bucket '$MOCK_BUCKET'\n" \
            && printf "\nListing bucket(s) now:\n" \
            && aws s3 ls --profile $S3_MOCK_LOCAL_PROFILE --endpoint http://$S3_DOCKER_HOST:$S3_DOCKER_PORT

    } || printf "\nWARNING: Something failed while trying to create new S3 bucket(s) ($MOCK_BUCKET)\nDo you have AWS CLI installed?\n"


else
    printf "ERROR: could NOT find mock S3 aws CLI profile setup script. Halting execution.\n"
    exit 1
fi


printf "\nFinished deployment. Listing current docker containers:\n"
$SUDO docker ps
printf "\n########### Finished running docker '${DOCKER_NAME}' ########### "
