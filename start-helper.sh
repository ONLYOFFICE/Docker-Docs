#!/usr/bin/env bash
set -e

export NODE_CONFIG='{
  "services": {
    "CoAuthoring": {
      "sql": {
        "dbHost": "'${DB_HOST:-localhost}'",
        "dbPort": '${DB_PORT:-5432}',
        "dbName": "'${DB_NAME:-onlyoffice}'",
        "dbUser": "'${DB_USER:-onlyoffice}'",
        "dbPass": "'${DB_PWD:-onlyoffice}'"
      },
      "redis": {
        "host": "'${REDIST_SERVER_HOST:-localhost}'",
        "port": '${REDIST_SERVER_PORT:-6379}'
      }
    }
  },
  "rabbitmq": {
    "url": "'${AMQP_URI:-"amqp://guest:guest@localhost"}'"
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }  
  }
}'

exec "$@"