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

if [[ -n "$REDIS_SENTINEL_NODES" ]]; then
  declare -a REDIS_SENTINEL_NODES_ALL=($REDIS_SENTINEL_NODES)
  REDIS_SENTINEL_NODES_ARRAY=()
  for node in "${REDIS_SENTINEL_NODES_ALL[@]}"; do
    host="${node%%:*}"
    port="${node##*:}"
    REDIS_SENTINEL_NODES_ARRAY+=('{ "host": "'$host'", "port": '$port' }')
  done
  OLD_IFS="$IFS"
  IFS=","
  NODES=$(echo "${REDIS_SENTINEL_NODES_ARRAY[*]}")
  IFS="$OLD_IFS"
  REDIS_SENTINEL='[ '$NODES' ],'
else
  REDIS_SENTINEL='[ { "host": "'${REDIS_SERVER_HOST:-localhost}'", "port": '${REDIS_SERVER_PORT:-6379}' } ],'
fi

if [[ -n "$REDIS_CLUSTER_NODES" ]]; then
  declare -a REDIS_CLUSTER_NODES_ALL=($REDIS_CLUSTER_NODES)
  REDIS_CLUSTER_NODES_ARRAY=()
  for node in "${REDIS_CLUSTER_NODES_ALL[@]}"; do
    REDIS_CLUSTER_NODES_ARRAY+=('{ "url": "redis://'$node'" }')
  done
  OLD_IFS="$IFS"
  IFS=","
  NODES=$(echo "${REDIS_CLUSTER_NODES_ARRAY[*]}")
  IFS="$OLD_IFS"
  REDIS_CLUSTER='"rootNodes": [ '$NODES' ], "defaults": { "username": "'${REDIS_SERVER_USER:-default}'", "password": "'$REDIS_SERVER_PWD'" }'
else
  REDIS_CLUSTER=''
fi

export NODE_CONFIG='{
  "statsd": {
    "useMetrics": '${METRICS_ENABLED:-false}',
    "host": "'${METRICS_HOST:-localhost}'",
    "port": '${METRICS_PORT:-8125}',
    "prefix": "'${METRICS_PREFIX:-ds.}'"
  },
  "runtimeConfig": {
    "filePath": "/var/www/'${COMPANY_NAME}'/config/runtime.json"
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
        "name": "'${REDIS_CONNECTOR_NAME:-redis}'",
        "host": "'${REDIS_SERVER_HOST:-${REDIST_SERVER_HOST:-localhost}}'",
        "port": '${REDIS_SERVER_PORT:-${REDIST_SERVER_PORT:-6379}}',
        "options": {
          "user": "'${REDIS_SERVER_USER:-default}'",
          "password": "'${REDIS_SERVER_PWD}'",
          "db": "'${REDIS_SERVER_DB_NUM:-0}'"
        },
        "optionsCluster": { '${REDIS_CLUSTER}' },
        "iooptions": {
          "sentinels": '${REDIS_SENTINEL}'
          "name": "'${REDIS_SENTINEL_GROUP_NAME:-mymaster}'",
          "sentinelPassword": "'${REDIS_SENTINEL_PWD}'",
          "username": "'${REDIS_SERVER_USER:-default}'",
          "password": "'${REDIS_SERVER_PWD}'",
          "db": "'${REDIS_SERVER_DB_NUM:-0}'"
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
        "browser": {
          "string": "'${JWT_SECRET_BROWSER:-${JWT_SECRET}}'"
        },
        "session": {
          "string": "'${JWT_SECRET}'"
        }
      },
      "request-filtering-agent" : {
        "allowPrivateIPAddress": '${ALLOW_PRIVATE_IP_ADDRESS:-false}',
        "allowMetaIPAddress": '${ALLOW_META_IP_ADDRESS:-false}',
        "allowIPAddressList": '${ALLOW_IP_ADDRESS_LIST:-[]}',
        "denyIPAddressList": '${DENY_IP_ADDRESS_LIST:-[]}'
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
    "enable": '${WOPI_ENABLED:-false}',
    "privateKey": "'${WOPI_PRIVATE_KEY}'",
    "privateKeyOld": "'${WOPI_PRIVATE_KEY_OLD}'",
    "publicKey": "'${WOPI_PUBLIC_KEY}'",
    "publicKeyOld": "'${WOPI_PUBLIC_KEY_OLD}'",
    "modulus": "'${WOPI_MODULUS_KEY}'",
    "modulusOld": "'${WOPI_MODULUS_KEY_OLD}'",
    "exponent": '${WOPI_EXPONENT_KEY:=65537}',
    "exponentOld": '${WOPI_EXPONENT_KEY_OLD:-${WOPI_EXPONENT_KEY}}'
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }
  },
  "storage": {
    "fs": {
      "folderPath": "/var/lib/'${COMPANY_NAME}'/documentserver/App_Data/cache/files/'${STORAGE_SUBDIRECTORY_NAME:-latest}'",
      "secretString": "'${SECURE_LINK_SECRET:-verysecretstring}'"
    },
    "storageFolderName": "files/'${STORAGE_SUBDIRECTORY_NAME:-latest}'"
  },
  "persistentStorage": {
    "fs": {
      "folderPath": "/var/lib/'${COMPANY_NAME}'/documentserver/App_Data/cache/files",
      "secretString": "'${SECURE_LINK_SECRET:-verysecretstring}'"
    },
    "storageFolderName": "files"
  }
}'

WORK_DIR="/var/www/$COMPANY_NAME/documentserver"
EXEC_CMD=""
BUILD_FONTS=false
BUILD_PLUGINS=false
BUILD_DICTIONARIES=false

while getopts ":c:fpd" opt; do
  case $opt in
    c ) EXEC_CMD="$(envsubst <<<"$OPTARG")" ;;
    f ) BUILD_FONTS=true ;;
    p ) BUILD_PLUGINS=true ;;
    d ) BUILD_DICTIONARIES=true ;;
    \?) ;;
  esac
done

shift $((OPTIND-1))
if [[ "${BUILD_FONTS}" == "true" ]]; then
  if [[ "${CONTAINER_NAME}" == "converter" ]]; then
    echo -e "\e[0;32m Build Fonts \e[0m"
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/Images/* $WORK_DIR/sdkjs/common/Images/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/themes/* $WORK_DIR/sdkjs/slide/themes/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/fonts/* $WORK_DIR/fonts/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/AllFonts.js $WORK_DIR/sdkjs/common/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/bin/* $WORK_DIR/server/FileConverter/bin/
  fi
else
  echo -e "\e[0;32m Do not Build Fonts \e[0m"
fi

if [[ "${BUILD_PLUGINS}" == "true" ]]; then
  if [[ "${CONTAINER_NAME}" != "converter" ]]; then
    if [[ -f "$WORK_DIR/sdkjs-plugins/build_plugins.txt" ]]; then
      echo "The plugins build has already been completed,skipping ..."
    else
      until cat $WORK_DIR/sdkjs-plugins/build_plugins.txt
      do
        echo "Waiting for the build plugins to complete"
        sleep 5
      done
    fi
    rm -rf $WORK_DIR/sdkjs-plugins/build_plugins.txt
  fi
else
  echo -e "\e[0;32m Do not Build PLUGINS \e[0m"
fi

if [[ "${BUILD_DICTIONARIES}" == "true" ]]; then
  if [[ "${CONTAINER_NAME}" == "converter" ]]; then
    echo -e "\e[0;32m Build Dictionaries \e[0m"
    ( find $WORK_DIR/sdkjs/cell $WORK_DIR/sdkjs/word $WORK_DIR/sdkjs/slide $WORK_DIR/sdkjs/visio -maxdepth 1 -type f \( -name '*.js' -o -name '*.bin' \)
      echo "$WORK_DIR/sdkjs/common/spell/spell/spell.js" ) | while read -r file; do
        chmod 740 "$file"
        dir=$(basename "$(dirname "$file")")
        echo $dir
        base_file=$(basename "$file")
        echo $base_file
        if [[ "${base_file}" == "spell.js" ]]; then
          target_dir="$WORK_DIR/sdkjs/common/spell/$dir"
        else
          target_dir="$WORK_DIR/sdkjs/$dir"
        fi
        echo cp -a "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/$dir/$base_file" "$target_dir/"
        cp -a "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/$dir/$base_file" "$target_dir/"
        chmod 440 "$target_dir/$base_file"
    done
    if [ "$(ls -A $WORK_DIR/dictionaries/)" ]; then
      echo "$WORK_DIR/dictionaries/ not empty"
      chmod 755 -R $WORK_DIR/dictionaries/*
      rm -rf $WORK_DIR/dictionaries/*
    fi
    cp -ra /var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/dictionaries/* $WORK_DIR/dictionaries/
  fi
else
  echo -e "\e[0;32m Do not Build DICTIONARIES \e[0m"
fi

if [[ -n "${EXEC_CMD}" ]]; then
  echo -e "\e[0;32m EXEC_CMD Exist \e[0m"
  exec -- "$EXEC_CMD" "$@"
else
  echo -e "\e[0;32m EXEC_CMD does not exist \e[0m"
fi
