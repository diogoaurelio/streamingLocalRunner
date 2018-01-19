#!/usr/bin/env bash


######################################
#
#   Convenience script to load events
#   in Docker kinesis
#
######################################

CURR_DIR=$PWD

source ${CURR_DIR}/kinesis.sh

while true
do
    SLEEP=5
    printf "Producing new random record in local docker kinesis every $SLEEP seconds ...\n"
    putRecord
    sleep $SLEEP
done
