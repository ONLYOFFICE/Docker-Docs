#!/usr/bin/env bash
set -e

if ! [ -d /tmp/proxy_nginx ]; then
  mkdir /tmp/proxy_nginx
fi
cp -r /etc/nginx/* /tmp/proxy_nginx/
sed 's|\(worker_connections\) [[:digit:]]*;|\1 '$NGINX_WORKER_CONNECTIONS';|g' -i /tmp/proxy_nginx/nginx.conf
sed "s/\(worker_processes\).*/\1 $NGINX_WORKER_PROCESSES;/" -i /tmp/proxy_nginx/nginx.conf
if [[ -n "$NGINX_LOG_FORMAT" ]]; then
  sed "s/\(log_format  main\).*/\1 '$NGINX_LOG_FORMAT';/" -i /tmp/proxy_nginx/nginx.conf
fi
if [ $NGINX_ACCESS_LOG != "off" ]; then
  sed 's|#*\(\s*access_log\).*;|\1 /var/log/nginx/access.log '$NGINX_ACCESS_LOG';|g' -i /tmp/proxy_nginx/nginx.conf
fi
envsubst < /tmp/proxy_nginx/includes/http-upstream.conf > /tmp/http-upstream.conf
envsubst < /etc/nginx/includes/ds-common.conf | tee /tmp/proxy_nginx/includes/ds-common.conf > /dev/null
sed "s,\(set \+\$secure_link_secret\).*,\1 "${SECURE_LINK_SECRET:-verysecretstring}";," -i /tmp/proxy_nginx/conf.d/ds.conf
sed "s/\(client_max_body_size\).*/\1 $NGINX_CLIENT_MAX_BODY_SIZE;/" -i /tmp/proxy_nginx/includes/ds-common.conf
if [[ ! -f "/proc/net/if_inet6" ]]; then
  sed '/listen\s\+\[::[0-9]*\].\+/d' -i /tmp/proxy_nginx/conf.d/ds.conf
fi
if [[ -n "$INFO_ALLOWED_IP" ]]; then
  declare -a IP_ALL=($INFO_ALLOWED_IP)
  for ip in "${IP_ALL[@]}"; do
    sed -i '/(info)/a\  allow '$ip'\;' /tmp/proxy_nginx/includes/ds-docservice.conf
  done
fi
if [[ -n "$INFO_ALLOWED_USER" ]]; then
  htpasswd -c -b /tmp/auth "${INFO_ALLOWED_USER}" "${INFO_ALLOWED_PASSWORD:-password}"
  sed -i '/(info)/a\  auth_basic \"Authentication Required\"\;' /tmp/proxy_nginx/includes/ds-docservice.conf
  sed -i '/auth_basic/a\  auth_basic_user_file \/tmp\/auth\;' /tmp/proxy_nginx/includes/ds-docservice.conf
fi

WORK_DIR="/var/www/$COMPANY_NAME/documentserver"
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

if [[ "${BUILD_FONTS}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/fonts/build_fonts.txt" ]]; then
    echo "The fonts build has already been completed,skipping ..."
  else
    echo -e "\e[0;32m Build Fonts \e[0m"
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/Images/* $WORK_DIR/sdkjs/common/Images/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/themes/* $WORK_DIR/sdkjs/slide/themes/
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/AllFonts.js $WORK_DIR/sdkjs/common/
    find $WORK_DIR/fonts \
      -type f ! \
      -name "*.*" \
      -exec sh -c 'gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz' {} \;
    chmod 755 $WORK_DIR/sdkjs/common/Images/cursors/
    find $WORK_DIR/sdkjs/common \
      $WORK_DIR/sdkjs/slide/themes \
      $WORK_DIR/sdkjs/common/Images \
      -type f \
      \( -name '*.js' -o -name '*.json' -o -name '*.htm' -o -name '*.html' -o -name '*.css' \) \
      -exec sh -c 'gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz' {} \;
    chmod 555 $WORK_DIR/sdkjs/common/Images/cursors/
    echo "Completed" > /var/lib/$COMPANY_NAME/documentserver/buffer/fonts/build_fonts.txt
  fi
else
  echo -e "\e[0;32m Do not Build Fonts \e[0m"
fi

if [[ "${BUILD_PLUGINS}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/plugins/build_plugins.txt" ]]; then
    echo "The plugins build has already been completed,skipping ..."
  else
    until cat /var/lib/$COMPANY_NAME/documentserver/buffer/plugins/build_plugins.txt
    do
      echo "Waiting for the build plugins to complete"
      sleep 5
    done
    echo -e "\e[0;32m Build PLUGINS \e[0m"
    cp -a /var/lib/$COMPANY_NAME/documentserver/buffer/plugins/sdkjs-plugins/* $WORK_DIR/sdkjs-plugins/
    find $WORK_DIR/sdkjs-plugins/* -type d -exec chmod u+w {} \;
    find $WORK_DIR/sdkjs-plugins \
      -type f \
      \( -name '*.js' -o -name '*.json' -o -name '*.htm' -o -name '*.html' -o -name '*.css' \) \
      -exec sh -c 'gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz' {} \;
  fi
else
  echo -e "\e[0;32m Do not Build PLUGINS \e[0m"
fi

if [[ "${BUILD_DICTIONARIES}" == "true" ]]; then
  if [[ -f "/var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/build_dictionaries.txt" ]]; then
    echo "The dictionaries build has already been completed,skipping ..."
  else
    until cat /var/lib/$COMPANY_NAME/documentserver/buffer/dictionaries/build_dictionaries.txt
    do
      echo "Waiting for the build dictionaries to complete"
      sleep 5
    done
    echo -e "\e[0;32m Build Dictionaries \e[0m"
    ( find $WORK_DIR/sdkjs/cell $WORK_DIR/sdkjs/word $WORK_DIR/sdkjs/slide $WORK_DIR/sdkjs/visio -maxdepth 1 -type f -name '*.js'
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
        gzip -cf9 "$target_dir/$base_file" > "$target_dir/$base_file.gz"
        chmod 440 "$target_dir/$base_file"
    done
  fi
else
  echo -e "\e[0;32m Do not Build DICTIONARIES \e[0m"
fi

exec nginx -c /tmp/proxy_nginx/nginx.conf -g 'daemon off;'
