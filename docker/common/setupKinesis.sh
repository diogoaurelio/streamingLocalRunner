#!/usr/bin/env bash


while [ $# -gt 0 ]; do
  case "$1" in
    --s=*)
      s="${1#*=}"
      ;;
    --name=*)
      name="${1#*=}"
      ;;
    --stream_name=*)
      stream_name="${1#*=}"
      ;;
    --num_shards=*)
      num_shards="${1#*=}"
      ;;
    --aws_region=*)
      aws_region="${1#*=}"
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

KINESIS_STREAM_NAME=${stream_name:-raw-events}
KINESIS_SHARD_COUNT=${num_shards:-3}
KINESIS_PORT=${kport:-4567}
AWS_REGION=${aws_region:-eu-central-1}
AWS_PROFILE=${aws_profile:-mycompany_local_aws_testing}


# import kinesis functions
source $PWD/kinesis.sh

printf "\nCreating new stream in local docker kinesis ...\n"
createStream ${KINESIS_STREAM_NAME} ${KINESIS_SHARD_COUNT} ${AWS_REGION} ${AWS_PROFILE} ${KINESIS_PORT}

printf "Validating if shard was successfully created ...\n"
sleep 3
describeStream ${KINESIS_STREAM_NAME} ${AWS_REGION} ${AWS_PROFILE} ${KINESIS_PORT}

printf "\nFinished setting up new stream in kinesis\nBye!\n"