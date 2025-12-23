#!/bin/bash

while [ "$1" != "" ]; do
  case $1 in
    * ) args+=("$1");
  esac
  shift
done

export LD_LIBRARY_PATH=/var/www/onlyoffice/documentserver/server/FileConverter/bin:$LD_LIBRARY_PATH

PLUGIN_MANAGER="/var/www/onlyoffice/documentserver/server/tools/pluginsmanager"
PLUGIN_DIR="/var/www/onlyoffice/documentserver/sdkjs-plugins/"

"${PLUGIN_MANAGER}" --directory=\"${PLUGIN_DIR}\" "${args[@]}"

chown -R ds:ds "${PLUGIN_DIR}"

echo "Plugins build is complete"
