#!/usr/bin/env bash
set -e

GZIP_FILES='gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz'

if [ ! -f /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts ]; then
	find /var/www/$COMPANY_NAME/documentserver/sdkjs \
	/var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
	/var/www/$COMPANY_NAME/documentserver/web-apps \
	/var/www/$COMPANY_NAME/documentserver-example/welcome \
	-type f \
	\( -name *.js -o -name *.json -o -name *.htm -o -name *.html -o -name *.css \) \
	-exec sh -c "$GZIP_FILES" {} \;
fi

source /usr/local/bin/fonts-generation.sh

if [ $FONTS_GENERATION = "true" ]; then
	find /var/www/$COMPANY_NAME/documentserver/fonts -type f ! -name "*.*" -exec sh -c "$GZIP_FILES" {} \;
	find /var/www/$COMPANY_NAME/documentserver -type f  -name "AllFonts.js" -exec sh -c "$GZIP_FILES" {} \;
fi

if ! [ -d /tmp/proxy_nginx ]; then 
	mkdir /tmp/proxy_nginx;
fi
cp -r /etc/nginx/* /tmp/proxy_nginx/
sed 's|\(worker_connections\) [[:digit:]]*;|\1 '$NGINX_WORKER_CONNECTIONS';|g' -i /tmp/proxy_nginx/nginx.conf
if [ $NGINX_ACCESS_LOG != "off" ]; then
	sed 's|#*\(\s*access_log\).*;|\1 /var/log/nginx/access.log '$NGINX_ACCESS_LOG';|g'
		-i /tmp/proxy_nginx/nginx.conf;
fi
sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /tmp/proxy_nginx/nginx.conf
envsubst < /tmp/proxy_nginx/includes/http-upstream.conf > /tmp/http-upstream.conf
envsubst < /etc/nginx/includes/ds-common.conf | tee /tmp/proxy_nginx/includes/ds-common.conf > /dev/null
sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /tmp/proxy_nginx/conf.d/ds.conf
exec nginx -c /tmp/proxy_nginx/nginx.conf -g 'daemon off;'
