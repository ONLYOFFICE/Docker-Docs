#!/usr/bin/env bash
set -e

DB_NAME=${DB_NAME:-localhost}
DB_NAME=${DB_NAME:-onlyoffice}
DB_USER=${DB_USER:-onlyoffice}
DB_PWD=${DB_PWD:-onlyoffice}
DB_TYPE=${DB_TYPE:-postgres}
REDIST_SERVER_HOST=${REDIST_SERVER_HOST:-localhost}
AMQP_URI=${AMQP_URI:-'amqp://guest:guest@localhost'}

export NODE_CONFIG='{"services":{"CoAuthoring":{"sql":{"dbHost": "'$DB_HOST'","dbName":"'$DB_NAME'","dbUser":"'$DB_USER'","dbPass":"'$DB_PWD'"},"redis":{"host": "'$REDIST_SERVER_HOST'","port":"6379"}}},"rabbitmq":{"url": "'$AMQP_URI'"}}'

echo $@

exec "$@"