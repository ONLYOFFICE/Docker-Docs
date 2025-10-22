#!/usr/bin/env bash
set -e

echo "$@"

WORK_DIR="/var/www/$COMPANY_NAME/documentserver"
EXEC_CMD=""
BUILD_FONTS=false
BUILD_PLUGINS=false
BUILD_DICTIONARIES=false

while getopts ":fpd" opt; do
  case $opt in
    f ) BUILD_FONTS=true ;;
    p ) BUILD_PLUGINS=true ;;
    d ) BUILD_DICTIONARIES=true ;;
    \?) ;;
  esac
done

echo "$EXEC_CMD"

if [[ "${BUILD_FONTS}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/fonts/build_fonts.txt" ]]; then
    echo "The fonts build has already been completed,skipping ..."
  else
    echo -e "\e[0;32m Build Fonts \e[0m"
    documentserver-generate-allfonts.sh true
    mkdir -p /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/bin
    cp -ra $WORK_DIR/sdkjs/common/Images/ /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/
    cp -ra $WORK_DIR/sdkjs/slide/themes/ /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/
    cp -a $WORK_DIR/sdkjs/common/AllFonts.js /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/
    if [[ "${CONTAINER_NAME}" == "converter" ]]; then
      cp -a $WORK_DIR/server/FileConverter/bin/AllFonts.js \
            $WORK_DIR/server/FileConverter/bin/font_selection.bin \
            $WORK_DIR/server/FileConverter/bin/fonts.log \
            /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/bin/
    fi
  fi
else
  echo -e "\e[0;32m Build Fonts NOT \e[0m"
fi

if [[ "${BUILD_PLUGINS}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/plugins/build_plugins.txt" ]]; then
    echo "The plugins build has already been completed,skipping ..."
  else
    echo -e "\e[0;32m Build PLUGINS \e[0m"
    documentserver-pluginsmanager.sh --update=\"/var/www/$COMPANY_NAME/documentserver/sdkjs-plugins/plugin-list-default.json\"
    mkdir /var/lib/$COMPANY_NAME/documentserver/buffer/plugins/
    if [[ "${CONTAINER_NAME}" == "docservice" ]]; then
      cp -ra $WORK_DIR/sdkjs-plugins/ /var/lib/$COMPANY_NAME/documentserver/buffer/plugins/
    fi
  fi
else
  echo -e "\e[0;32m Build PLUGINS NOT \e[0m"
fi

if [[ "${BUILD_DICTIONARIES}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/build_dictionaries.txt" ]]; then
    echo "The dictionaries build has already been completed,skipping ..."
  else
    echo -e "\e[0;32m Build Dictionaries \e[0m"
    ( find $WORK_DIR/sdkjs/cell $WORK_DIR/sdkjs/word $WORK_DIR/sdkjs/slide $WORK_DIR/sdkjs/visio -maxdepth 1 -type f -name '*.js'
      echo "$WORK_DIR/sdkjs/common/spell/spell/spell.js" ) | while read -r file; do
        chmod 740 "$file"
    done
    python3 $WORK_DIR/server/dictionaries/update.py
    mkdir /var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/
    if [[ "${CONTAINER_NAME}" == "docservice" ]]; then
      mkdir -p /var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/spell
      ( find $WORK_DIR/sdkjs/cell $WORK_DIR/sdkjs/word $WORK_DIR/sdkjs/slide $WORK_DIR/sdkjs/visio -maxdepth 1 -type f -name '*.js'
        echo "$WORK_DIR/sdkjs/common/spell/spell/spell.js" ) | while read -r file; do
          dir=$(basename "$(dirname "$file")")
          mkdir -p "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/$dir"
          cp -a "$file" "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/$dir/"
      done
    fi
    echo "Completed" > /var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/build_dictionaries.txt
  fi
else
  echo -e "\e[0;32m Build DICTIONARIES NOT \e[0m"
fi
