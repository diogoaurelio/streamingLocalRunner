#!/usr/bin/env bash

######################################
#
#   Convenience functions to interact with
#   with Docker kinesis
#
######################################

function createStream(){
    KINESIS_STREAM_NAME=${1}
    KINESIS_SHARD_COUNT=${2}
    AWS_REGION=${3}
    AWS_PROFILE=${4}
    DOCKER_PORT=${5:-4567}
    aws kinesis create-stream \
        --stream-name $KINESIS_STREAM_NAME \
        --shard-count $KINESIS_SHARD_COUNT \
        --region ${AWS_REGION} \
        --profile ${AWS_PROFILE} \
        --endpoint http://localhost:${DOCKER_PORT}
}

function describeStream(){
    KINESIS_STREAM_NAME=${1}
    AWS_REGION=${2}
    AWS_PROFILE=${3}
    DOCKER_PORT=${4:-4567}

    aws kinesis describe-stream \
        --stream-name ${KINESIS_STREAM_NAME} \
        --region ${AWS_REGION} \
        --profile ${AWS_PROFILE} \
        --endpoint http://localhost:${DOCKER_PORT}
}

function echoNewEvent(){


    RAND_PRODUCT_ID=$(seq 1 2 | shuf -n 1)
    PRODUCT_ID=${1:-${RAND_PRODUCT_ID}}
    EVENT_NAME=${2:-product_click}
    EVENT_VERSION=${3:-0.01}


    # note: on osx has to be different than debian!
    TIMESTAMP_OSX=${4:-$(date +%s%3N)}
    TIMESTAMP=${5:-$(date +%s)}
    DATE=$(date -d @$TIMESTAMP '+%Y-%m-%d %H:%M:%S')
    DATE_TIME="$DATE.000Z"
    MARKET=${6:-de}
    DELIVERY_CHANNEL=${7:-dest.mycompany-subbrand}
    USER_PLATFORM_OS="Android"
    USER_PLATFORM_CATEGORY="phone.web.browser"
    CLICK_UUID=$(uuidgen)
    USER_ID=$(seq 1 20 | shuf -n 1)

    IP="1.1.1.1"
    USER_AGENT="retale Android(release;model/LGLS775;sdk/24;lang/en)"

    NO_PROFILE="false"

    VISIT_ORIGIN_TYPE="MOBILEWEB_REQUEST_DBC_CAMPAIGN_ADWORDS_DESKTOP"
    CAMPAIGN_CHANNEL_TYPE="ADWORDS_MOBILE"
    SESSION_ID=$(shuf -i 2000-6500000 -n 1)

    LOCAL_DATETIME_RECEIVED=$(date -d @$TIMESTAMP '+%Y-%m-%dT%H:%M:%S' --date '-2 hours')
    EVENT_TIMESTAMP=$(date -d @$TIMESTAMP '+%Y-%m-%dT%H:%M:%S')
    DATETIME_RECEIVED="$EVENT_TIMESTAMP.000Z"
    EVENT_UTC_TZ="$EVENT_TIMESTAMP.000Z"


    TEST_DATA="""{\"click_uuid\":\"${CLICK_UUID}\",\"product_id\":${PRODUCT_ID},\"campaign_channel_type\":\"${CAMPAIGN_CHANNEL_TYPE}\",\"date_time\":\"${DATE_TIME}\",\"date_time_received\":\"${DATETIME_RECEIVED}\",\"event_name\":\"${EVENT_NAME}\",\"event_utc_tz\":\"${EVENT_UTC_TZ}\",\"event_version\":${EVENT_VERSION},\"ip\":\"${IP}\",\"market\":\"${MARKET}\",\"session_id\":\"${SESSION_ID}\",\"user_agent\":\"${USER_AGENT}\",\"user_id\":\"${USER_ID}\",\"user_platform_browser\":\"unknown\",\"user_platform_browser_ver\":\"4.0\",\"user_platform_category\":\"${USER_PLATFORM_CATEGORY}\",\"user_platform_os\":\"${USER_PLATFORM_OS}\",\"user_platform_os_ver\":\"5.1.1\",\"visit_id\":${SESSION_ID},\"visit_origin_type\":\"${VISIT_ORIGIN_TYPE}\"}"""

    echo ${TEST_DATA}
}

function putRecord(){
    DEFAULT_TEST_DATA=$(echoNewEvent)

    KINESIS_STREAM_NAME=${1:-raw-events}
    DATA=${2:-$DEFAULT_TEST_DATA}
    RANDOM_SHARD=$(shuf -i 0-2 -n 1)
    KINESIS_SHARD_ID=${3:-"shardId-00000000000$RANDOM_SHARD"}
    printf "Data being published in local kinesis docker: $DATA\n"

    AWS_REGION=${4:-eu-central-1}
    AWS_PROFILE=${5:-mycompany_local_aws_testing}
    DOCKER_PORT=${6:-4567}

    aws kinesis put-record \
        --stream-name ${KINESIS_STREAM_NAME} \
        --data "${DATA}" \
        --partition-key ${KINESIS_SHARD_ID} \
        --region ${AWS_REGION} \
        --profile ${AWS_PROFILE} \
        --endpoint http://localhost:${DOCKER_PORT}
}