#!/bin/bash

# Define '**' behavior explicitly
shopt -s globstar

APP_DIR="/var/www/${COMPANY_NAME}/documentserver"
LOG_DIR="/var/log/${COMPANY_NAME}"
DS_LOG_DIR="${LOG_DIR}/documentserver"
LIB_DIR="/var/lib/${COMPANY_NAME}"
DS_LIB_DIR="${LIB_DIR}/documentserver"
CONF_DIR="/etc/${COMPANY_NAME}/documentserver"

DATA_CONTAINER=${DATA_CONTAINER:-false}
DATA_CONTAINER_HOST=${DATA_CONTAINER_HOST:-localhost}
DATA_CONTAINER_PORT=8888

DEFAULT_CONFIG=${CONF_DIR}/local.json

JSON_BIN=${APP_DIR}/npm/node_modules/.bin/json
JSON="${JSON_BIN} -q -f ${DEFAULT_CONFIG}"

read_setting(){
  DB_HOST=$(${JSON} services.CoAuthoring.sql.dbHost)
  DB_PORT=$(${JSON} services.CoAuthoring.sql.dbPort)
  DB_NAME=$(${JSON} services.CoAuthoring.sql.dbName)
  DB_USER=$(${JSON} services.CoAuthoring.sql.dbUser)
  DB_PASS=$(${JSON} services.CoAuthoring.sql.dbPass)

  AMQP_URI=$(${JSON} rabbitmq.url)
  parse_rabbitmq_url

  REDIS_SERVER_HOST=$(${JSON} services.CoAuthoring.redis.host)
  REDIS_SERVER_PORT=6379
}

parse_rabbitmq_url(){
  local amqp=${AMQP_URI}

  # extract the protocol
  local proto="$(echo $amqp | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  # remove the protocol
  local url="$(echo ${amqp/$proto/})"

  # extract the user and password (if any)
  local userpass="`echo $url | grep @ | cut -d@ -f1`"
  local pass=`echo $userpass | grep : | cut -d: -f2`

  local user
  if [ -n "$pass" ]; then
    user=`echo $userpass | grep : | cut -d: -f1`
  else
    user=$userpass
  fi

  # extract the host
  local hostport="$(echo ${url/$userpass@/} | cut -d/ -f1)"
  # by request - try to extract the port
  local port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

  local host
  if [ -n "$port" ]; then
    host=`echo $hostport | grep : | cut -d: -f1`
  else
    host=$hostport
    port="5672"
  fi

  # extract the path (if any)
  local path="$(echo $url | grep / | cut -d/ -f2-)"

  RABBITMQ_SERVER_HOST=$host
  RABBITMQ_SERVER_USER=$user
  RABBITMQ_SERVER_PASS=$pass
  RABBITMQ_SERVER_PORT=$port
}

waiting_for_connection(){
  until nc -z -w 3 "$1" "$2"; do
    >&2 echo "Waiting for connection to the $3 service on $1 host on port $2"
    sleep 1
  done
}

waiting_for_postgresql(){
  waiting_for_connection ${DB_HOST} ${DB_PORT} "postgresql"
}

waiting_for_rabbitmq(){
  waiting_for_connection ${RABBITMQ_SERVER_HOST} ${RABBITMQ_SERVER_PORT} "rabbit"
}

waiting_for_redis(){
  waiting_for_connection ${REDIS_SERVER_HOST} ${REDIS_SERVER_PORT} "redis"
}
waiting_for_datacontainer(){
  waiting_for_connection ${DATA_CONTAINER_HOST} ${DATA_CONTAINER_PORT} "data"
}

create_postgresql_tbl(){
  CONNECTION_PARAMS="-h${DB_HOST} -U${DB_USER} -w"
  if [ -n "${DB_PASS}" ]; then
    export PGPASSWORD=${DB_PASS}
  fi

  PSQL="psql -q $CONNECTION_PARAMS"

  $PSQL -d "${DB_NAME}" -f "${APP_DIR}/server/schema/postgresql/createdb.sql"
}


# create base folders
for i in converter docservice spellchecker metrics gc; do
  mkdir -p "${DS_LOG_DIR}/$i"
done

mkdir -p ${DS_LOG_DIR}-example

# create app folders
for i in App_Data/cache/files App_Data/docbuilder; do
  mkdir -p "${DS_LIB_DIR}/$i"
done

documentserver-generate-allfonts.sh true

if [ ${DATA_CONTAINER} = "true" ]; then
  read_setting

  waiting_for_postgresql
  create_postgresql_tbl

  nginx -g 'daemon off;'
else
  waiting_for_datacontainer
  read_setting

  waiting_for_postgresql
  waiting_for_rabbitmq
  waiting_for_redis

  supervisord -n -c /etc/supervisord.conf
fi
