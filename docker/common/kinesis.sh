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


    RAND_BROCHURE_ID=$(seq 1 2 | shuf -n 1)
    BROCHURE_ID=${1:-${RAND_BROCHURE_ID}}
    EVENT_NAME=${2:-brochure_click}
    EVENT_VERSION=${3:-0.01}


    # note: on osx has to be different than debian!
    TIMESTAMP_OSX=${4:-$(date +%s%3N)}
    TIMESTAMP=${5:-$(date +%s)}
    DATE=$(date -d @$TIMESTAMP '+%Y-%m-%d %H:%M:%S')
    DATE_TIME="$DATE.000Z"
    MARKET=${6:-de}
    DELIVERY_CHANNEL=${7:-dest.kaufda}
    USER_PLATFORM_OS="Android"
    USER_PLATFORM_CATEGORY="phone.web.browser"
    BROCHURE_CLICK_UUID=$(uuidgen)
    USER_IDENT=$(seq 1 20 | shuf -n 1)

    PREVIEW="false"
    TREATMENT="RESPONSIVE and some non-escaped goodie's"
    RESTRICTED_IP="false"
    IP="99.1.198.37"
    USER_AGENT="retale Android(release;model/LGLS775;sdk/24;lang/en)"
    LAT="-38.61149910166468"
    LNG="-76.91214534706012"
    PAGE_TYPE="US-P-Brochure_DBC"
    USER_ZIP=$(shuf -i 2000-65000 -n 1)
    NO_PROFILE="false"
    PAGE=$(shuf -i 1-10 -n 1)

    VISIT_ORIGIN_TYPE="MOBILEWEB_REQUEST_DBC_CAMPAIGN_ADWORDS_DESKTOP"
    TRAFFIC_SOURCE_TYPE="AFFILIATE_RETAILER_SLOT"
    TRAFFIC_SOURCE_VALUE=30914592
    CAMPAIGN_CHANNEL_TYPE="ADWORDS_MOBILE"
    # visit_id=session_id
    SESSION_ID=$(shuf -i 2000-6500000 -n 1)

    LOCAL_DATETIME_RECEIVED=$(date -d @$TIMESTAMP '+%Y-%m-%dT%H:%M:%S' --date '-2 hours')
    EVENT_TIMESTAMP=$(date -d @$TIMESTAMP '+%Y-%m-%dT%H:%M:%S')
    DATETIME_RECEIVED="$EVENT_TIMESTAMP.000Z"
    EVENT_UTC_TZ="$EVENT_TIMESTAMP.000Z"

#    printf "USER_IDENT: $USER_IDENT \n"
#    printf "BROCHURE_ID: $BROCHURE_ID \n"
#
#    printf "DATE_TIME: $DATE_TIME \n"
#    printf "LOCAL_DATETIME_RECEIVED: $LOCAL_DATETIME_RECEIVED \n"
#    printf "DATETIME_RECEIVED: $DATETIME_RECEIVED \n"
#    printf "EVENT_UTC_TZ: $EVENT_UTC_TZ \n"

    TEST_DATA="""{\"brochure_click_uuid\":\"${BROCHURE_CLICK_UUID}\",\"brochure_id\":${BROCHURE_ID},\"campaign_channel_type\":\"${CAMPAIGN_CHANNEL_TYPE}\",\"date_time\":\"${DATE_TIME}\",\"date_time_received\":\"${DATETIME_RECEIVED}\",\"delivery_channel\":\"${DELIVERY_CHANNEL}\",\"event\":\"${EVENT_NAME}\",\"event_classifier\":\"${DELIVERY_CHANNEL}.tracking_api.${EVENT_NAME}\",\"event_name\":\"${EVENT_NAME}\",\"event_utc_tz\":\"${EVENT_UTC_TZ}\",\"event_version\":${EVENT_VERSION},\"ip\":\"${IP}\",\"location_intended_lat\":${LAT},\"location_intended_lng\":${LNG},\"market\":\"${MARKET}\",\"no_profile\":${NO_PROFILE},\"page\":${PAGE},\"page_type\":\"${PAGE_TYPE}\",\"partner\":\"retale_web\",\"preview\":${PREVIEW},\"preview_user\":${PREVIEW},\"restricted_ip\":${RESTRICTED_IP},\"session_id\":\"${SESSION_ID}\",\"traffic_source_type\":\"${TRAFFIC_SOURCE_TYPE}\",\"traffic_source_value\":\"${TRAFFIC_SOURCE_VALUE}\",\"treatment\":\"${TREATMENT}\",\"user_agent\":\"${USER_AGENT}\",\"user_ident\":\"${USER_IDENT}\",\"user_ip\":\"${IP}\",\"user_location_lat\":${LAT},\"user_location_lng\":${LNG},\"user_location_zip\":\"${USER_ZIP}\",\"user_platform_browser\":\"unknown\",\"user_platform_browser_ver\":\"4.0\",\"user_platform_category\":\"${USER_PLATFORM_CATEGORY}\",\"user_platform_os\":\"${USER_PLATFORM_OS}\",\"user_platform_os_ver\":\"5.1.1\",\"user_web_id\":\"150947042619332\",\"user_zip\":\"${USER_ZIP}\",\"visit_id\":${SESSION_ID},\"visit_origin_type\":\"${VISIT_ORIGIN_TYPE}\"}"""

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