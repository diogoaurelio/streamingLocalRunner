#!/usr/bin/env bash

################################
#
# Script used to setup AWS CLI
# profile
#
################################



AWS_MOCK_KEY=${1:-MY_ACCESS_KEY}
AWS_MOCK_SECRET=${2:-MY_SECRET_KEY}
AWS_REGION=${3:-eu-central-1}
S3_MOCK_LOCAL_PROFILE=${4:-mycompany_local_aws_testing}

printf "Creating locally AWS fake profile under name '$S3_MOCK_LOCAL_PROFILE' (key: $AWS_MOCK_KEY, secret: $AWS_MOCK_SECRET, region: $AWS_REGION) \n"
printf "${AWS_MOCK_KEY}\n${AWS_MOCK_SECRET}\n${AWS_REGION}\njson" | aws configure --profile ${S3_MOCK_LOCAL_PROFILE}
