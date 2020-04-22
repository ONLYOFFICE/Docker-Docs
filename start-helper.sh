#!/usr/bin/env bash
set -e

export NODE_CONFIG='{
  "services": {
    "CoAuthoring": {
      "sql": {
        "dbHost": "'${DB_HOST:-localhost}'",
        "dbPort": '${DB_PORT:-5432}',
        "dbUser": "'${DB_USER:=onlyoffice}'",
        "dbName": "'${DB_NAME:-${DB_USER}}'",
        "dbPass": "'${DB_PWD:-onlyoffice}'"
      },
      "redis": {
        "host": "'${REDIST_SERVER_HOST:-localhost}'",
        "port": '${REDIST_SERVER_PORT:-6379}'
      },
      "token": {
        "enable": {
          "browser": '${JWT_ENABLED:=false}',
          "request": {
            "inbox": '${JWT_ENABLED}',
            "outbox": '${JWT_ENABLED}' 
          }
        },
        "inbox": {
          "header": "'${JWT_HEADER:=Authorization}'",
          "inBody": '${JWT_IN_BODY:=false}'
        },
        "outbox": {
          "header": "'${JWT_HEADER}'",
          "inBody": '${JWT_IN_BODY}'
        }        
      },
      "secret": {
        "inbox": {
          "string": "'${JWT_SECRET:=secret}'"
        },
        "outbox": {
          "string": "'${JWT_SECRET}'"
        },
        "session": {
          "string": "'${JWT_SECRET}'"
        }        
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