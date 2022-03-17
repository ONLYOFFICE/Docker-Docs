#!/usr/bin/env bash
set -e

if [[ -n ${LOG_LEVEL} ]]; then
  sed 's/\(^.\+"level":\s*"\).\+\(".*$\)/\1'$LOG_LEVEL'\2/g' -i /etc/$COMPANY_NAME/documentserver/log4js/production.json
fi

if [[ -n ${LOG_TYPE} ]]; then
  sed 's/\("type"\:\) "pattern"/\1 "'$LOG_TYPE'"/' -i /etc/$COMPANY_NAME/documentserver/log4js/production.json
fi

if [[ -n ${LOG_PATTERN} ]]; then
  sed "s/\(\"pattern\"\:\).*/\1 \"$LOG_PATTERN\"/" -i /etc/$COMPANY_NAME/documentserver/log4js/production.json
fi

export NODE_CONFIG='{
  "statsd": {
    "useMetrics": '${METRICS_ENABLED:-false}',
		"host": "'${METRICS_HOST:-localhost}'",
		"port": '${METRICS_PORT:-8125}',
		"prefix": "'${METRICS_PREFIX:-ds.}'"
	},
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
    "url": "'${AMQP_URI:-${AMQP_PROTO:-amqp}://${AMQP_USER:-guest}:${AMQP_PWD:-guest}@${AMQP_HOST:-localhost}}'"
  },
  "wopi": {
    "enable": "'${WOPI_ENABLED:-false}'"
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }  
  }
}'

exec "$@"
