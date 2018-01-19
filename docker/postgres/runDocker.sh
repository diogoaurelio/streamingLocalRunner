#!/usr/bin/env bash

##########################################
#
#   Starts a new Postgres Docker
#   Notes:
#           data is NOT persisted on purpose;
#           optionally takes named params;
#          --s: in case your docker is installed with sudo
#               pass in the option --s=sudo; do NOT run the
#               script with sudo bash runDocker.sh;
#               by default sudo is NOT used
#          --name: optionally pass another name to docker
#                  container;
#                  by default "mycompany_postgres"
#          --port: postgres port exported to the outside
#                   by default "15432"
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
    --pg_user=*)
      pg_user="${1#*=}"
      ;;
    --pg_pwd=*)
      pg_pwd="${1#*=}"
      ;;
    --pg_db=*)
      pg_db="${1#*=}"
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
DOCKER_NAME=${name:-mycompany_postgres}
PG_PORT=${port:-15432}
PG_DB=${pg_db:-realtimebilling}
PG_USER=${pg_user:-postgres}
PG_PWD=${pg_pwd:-mysecretpassword}

DOCKER_DIR=$(dirname "${PWD}")
ROOT_DIR=$(dirname "${DOCKER_DIR}")


bash stopDocker.sh --name=$DOCKER_NAME --s=$SUDO || echo "No docker container called '${DOCKER_NAME}' found running."

#export PGPASSWORD='mysecretpassword' && psql -h localhost -d realtimebilling -p 5432 --user postgres -a -f /tmp/tests/resources/create_tables_portal_2011.sql

echo "Starting $DOCKER_NAME container"
$SUDO docker run -d --name $DOCKER_NAME \
    -p ${PG_PORT}:5432 \
    -e POSTGRES_USER=$PG_USER \
    -e POSTGRES_DB=$PG_DB \
    -e POSTGRES_PASSWORD=$PG_PWD \
    -v ${ROOT_DIR}/tests/resources/:/docker-entrypoint-initdb.d/ \
    --net=mycompany \
    postgres:9.6

