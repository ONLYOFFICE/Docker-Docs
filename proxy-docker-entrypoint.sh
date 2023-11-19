#!/usr/bin/env bash
set -e

if ! [ -d /tmp/proxy_nginx ]; then
  mkdir /tmp/proxy_nginx
fi
cp -r /etc/nginx/* /tmp/proxy_nginx/
sed 's|\(worker_connections\) [[:digit:]]*;|\1 '$NGINX_WORKER_CONNECTIONS';|g' -i /tmp/proxy_nginx/nginx.conf
if [ $NGINX_ACCESS_LOG != "off" ]; then
  sed 's|#*\(\s*access_log\).*;|\1 /var/log/nginx/access.log '$NGINX_ACCESS_LOG';|g' -i /tmp/proxy_nginx/nginx.conf
fi
envsubst < /tmp/proxy_nginx/includes/http-upstream.conf > /tmp/http-upstream.conf
envsubst < /etc/nginx/includes/ds-common.conf | tee /tmp/proxy_nginx/includes/ds-common.conf > /dev/null
sed "s,\(set \+\$secure_link_secret\).*,\1 "${SECURE_LINK_SECRET:-verysecretstring}";," -i /tmp/proxy_nginx/conf.d/ds.conf
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
exec nginx -c /tmp/proxy_nginx/nginx.conf -g 'daemon off;'
