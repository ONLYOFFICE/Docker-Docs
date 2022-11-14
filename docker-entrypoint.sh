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

ACTIVEMQ_TRANSPORT=""
case $AMQP_PROTO in
  amqps | amqp+ssl)
    ACTIVEMQ_TRANSPORT="tls"
    ;;
  *)
    ACTIVEMQ_TRANSPORT="tcp"
    ;;
esac

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
        "type": "'${DB_TYPE:-postgres}'",
        "dbHost": "'${DB_HOST:-localhost}'",
        "dbPort": '${DB_PORT:-5432}',
        "dbUser": "'${DB_USER:=onlyoffice}'",
        "dbName": "'${DB_NAME:-${DB_USER}}'",
        "dbPass": "'${DB_PWD:-onlyoffice}'"
      },
      "redis": {
        "host": "'${REDIS_SERVER_HOST:-${REDIST_SERVER_HOST:-localhost}}'",
        "port": '${REDIS_SERVER_PORT:-${REDIST_SERVER_PORT:-6379}}',
        "options": {
          "user": "'${REDIS_SERVER_USER:=default}'",
          "password": "'${REDIS_SERVER_PWD}'",
          "db": "'${REDIS_SERVER_DB_NUM:=0}'"
        }
      },
      "token": {
        "enable": {
          "browser": '${JWT_ENABLED:=true}',
          "request": {
            "inbox": '${JWT_ENABLED_INBOX:-${JWT_ENABLED}}',
            "outbox": '${JWT_ENABLED_OUTBOX:-${JWT_ENABLED}}'
          }
        },
        "inbox": {
          "header": "'${JWT_HEADER_INBOX:-${JWT_HEADER:=Authorization}}'",
          "inBody": '${JWT_IN_BODY:=false}'
        },
        "outbox": {
          "header": "'${JWT_HEADER_OUTBOX:-${JWT_HEADER}}'",
          "inBody": '${JWT_IN_BODY}'
        }
      },
      "secret": {
        "inbox": {
          "string": "'${JWT_SECRET_INBOX:-${JWT_SECRET:=secret}}'"
        },
        "outbox": {
          "string": "'${JWT_SECRET_OUTBOX:-${JWT_SECRET}}'"
        },
        "session": {
          "string": "'${JWT_SECRET}'"
        }        
      }
    }
  },
  "queue": {
    "type": "'${AMQP_TYPE:=rabbitmq}'"
  },
  "activemq": {
    "connectOptions": {
      "port": "'${AMQP_PORT:=5672}'",
      "host": "'${AMQP_HOST:=localhost}'",
      "username": "'${AMQP_USER:=guest}'",
      "password": "'${AMQP_PWD:=guest}'",
      "transport": "'${ACTIVEMQ_TRANSPORT}'"
    }
  },
  "rabbitmq": {
    "url": "'${AMQP_URI:-${AMQP_PROTO:-amqp}://${AMQP_USER}:${AMQP_PWD}@${AMQP_HOST}:${AMQP_PORT}${AMQP_VHOST:-/}}'"
  },
  "wopi": {
    "enable": '${WOPI_ENABLED:-false}'
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }  
  },
  "storage": {
    "fs": {
      "secretString": "'${SECURE_LINK_SECRET:-verysecretstring}'"
    }
  }
}'

exec "$@"
