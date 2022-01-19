FROM centos:7 AS ds-base

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ENV COMPANY_NAME=$COMPANY_NAME \
    NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver
RUN groupadd --system --gid 101 ds && \
    useradd --system -g ds --no-create-home --shell /sbin/nologin --uid 101 ds && \
    rm -f /var/log/*log

FROM ds-base AS ds-service
ARG PRODUCT_EDITION=
ARG PRODUCT_URL=http://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver$PRODUCT_EDITION.x86_64.rpm
RUN useradd --no-create-home --shell /sbin/nologin nginx && \
    yum -y install epel-release && \
    yum -y updateinfo && \
    yum -y install cabextract fontconfig xorg-x11-font-utils xorg-x11-server-utils && \
    rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm && \
    rpm -ivh $PRODUCT_URL --noscripts --nodeps && \
    mkdir -p /var/www/$COMPANY_NAME/documentserver/core-fonts/msttcore && \
    cp -vt \
        /var/www/$COMPANY_NAME/documentserver/core-fonts/msttcore \
        /usr/share/fonts/msttcore/*.ttf && \
    chmod a+r /etc/$COMPANY_NAME/documentserver*/*.json && \
    chmod a+r /etc/$COMPANY_NAME/documentserver/log4js/*.json
COPY --chown=ds:ds \
    config/nginx/includes/http-common.conf \
    config/nginx/includes/http-upstream.conf \
    /etc/$COMPANY_NAME/documentserver/nginx/includes/
COPY --chown=ds:ds \
    fonts/* \
    /var/www/$COMPANY_NAME/documentserver/core-fonts/custom/
COPY --chown=ds:ds \
    plugins/* \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins/
RUN documentserver-generate-allfonts.sh true

FROM ds-base AS proxy
ENV DOCSERVICE_HOST_PORT=localhost:8000 \
    EXAMPLE_HOST_PORT=localhost:3000 \
    NGINX_ACCESS_LOG=off \
    NGINX_GZIP_PROXIED=off \
    NGINX_WORKER_CONNECTIONS=4096
EXPOSE 8888
RUN yum -y install epel-release sudo && \
    yum -y updateinfo && \
    yum -y install gettext nginx && \
    yum clean all && \
    rm -f /var/log/*log
COPY --chown=ds:ds config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=ds:ds --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/nginx/ds.conf \
    /etc/nginx/conf.d/
COPY --chown=ds:ds --from=ds-service \
    /etc/$COMPANY_NAME/documentserver*/nginx/includes/*.conf \
    /etc/nginx/includes/
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/fonts \
    /var/www/$COMPANY_NAME/documentserver/fonts
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs \
    /var/www/$COMPANY_NAME/documentserver/sdkjs
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/web-apps \
    /var/www/$COMPANY_NAME/documentserver/web-apps
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/dictionaries \
    /var/www/$COMPANY_NAME/documentserver/dictionaries
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver-example/welcome \
    /var/www/$COMPANY_NAME/documentserver-example/welcome
RUN sed 's|\(application\/zip.*\)|\1\n    application\/wasm wasm;|' \
        -i /etc/nginx/mime.types && \
    sed 's,\(listen.\+:\)\([0-9]\+\)\(.*;\),'"\18888\3"',' \
        -i /etc/nginx/conf.d/ds.conf && \
    sed '/access_log.*/d' -i /etc/nginx/includes/ds-common.conf && \
    sed '/error_log.*/d' -i /etc/nginx/includes/ds-common.conf && \
    echo -e "\ngzip_proxied \$NGINX_GZIP_PROXIED;\n" >> /etc/nginx/includes/ds-common.conf && \
    sed 's/#*\s*\(gzip_static\).*/\1 on;/g' -i /etc/nginx/includes/ds-docservice.conf && \
    chmod 755 /var/log/nginx && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder && \
    chown -R ds:ds /var/lib/$COMPANY_NAME/documentserver && \
    find \
        /var/www/$COMPANY_NAME/documentserver/fonts \
        -type f ! \
        -name "*.*" \
        -exec sh -c 'gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz' {} \; && \
    find \
        /var/www/$COMPANY_NAME/documentserver/sdkjs \
        /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
        /var/www/$COMPANY_NAME/documentserver/web-apps \
        /var/www/$COMPANY_NAME/documentserver-example/welcome \
        -type f \
        \( -name *.js -o -name *.json -o -name *.htm -o -name *.html -o -name *.css \) \
        -exec sh -c 'gzip -cf9 $0 > $0.gz && chown ds:ds $0.gz' {} \;
VOLUME /var/lib/$COMPANY_NAME
USER ds
ENTRYPOINT \
    if ! [ -d /tmp/proxy_nginx ]; then \
        mkdir /tmp/proxy_nginx; \
    fi && \
    cp -r /etc/nginx/* /tmp/proxy_nginx/ && \
    sed 's|\(worker_connections\) [[:digit:]]*;|\1 '$NGINX_WORKER_CONNECTIONS';|g' \
        -i /tmp/proxy_nginx/nginx.conf && \
    if [ $NGINX_ACCESS_LOG != "off" ]; then \
        sed 's|#*\(\s*access_log\).*;|\1 /var/log/nginx/access.log '$NGINX_ACCESS_LOG';|g' \
            -i /tmp/proxy_nginx/nginx.conf; \
    fi && \
    sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /tmp/proxy_nginx/nginx.conf && \
    envsubst < /tmp/proxy_nginx/includes/http-upstream.conf > /tmp/http-upstream.conf && \
    envsubst < /etc/nginx/includes/ds-common.conf | tee /tmp/proxy_nginx/includes/ds-common.conf > /dev/null && \
    sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /tmp/proxy_nginx/conf.d/ds.conf && \
    sed 's/\(X-Forwarded-For\).*/\1 example.com;/' -i /tmp/proxy_nginx/includes/ds-example.conf && \
    exec nginx -c /tmp/proxy_nginx/nginx.conf -g 'daemon off;'

FROM ds-base AS docservice
EXPOSE 8000
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/default.json \
    /etc/$COMPANY_NAME/documentserver/production-linux.json \
    /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-service --chown=ds:ds \
    /etc/$COMPANY_NAME/documentserver/log4js/production.json \
    /etc/$COMPANY_NAME/documentserver/log4js/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/DocService \
    /var/www/$COMPANY_NAME/documentserver/server/DocService
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/info \
    /var/www/$COMPANY_NAME/documentserver/server/info
COPY docker-entrypoint.sh /usr/local/bin/
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/DocService/docservice
HEALTHCHECK --interval=10s --timeout=3s CMD curl -sf http://localhost:8000/index.html

FROM ds-base AS converter
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/default.json \
    /etc/$COMPANY_NAME/documentserver/production-linux.json \
    /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-service --chown=ds:ds \
    /etc/$COMPANY_NAME/documentserver/log4js/production.json \
    /etc/$COMPANY_NAME/documentserver/log4js/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/core-fonts \
    /var/www/$COMPANY_NAME/documentserver/core-fonts
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/fonts \
    /var/www/$COMPANY_NAME/documentserver/fonts
COPY --from=ds-service \
    /usr/share/fonts \
    /usr/share/fonts
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs \
    /var/www/$COMPANY_NAME/documentserver/sdkjs
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/FileConverter \
    /var/www/$COMPANY_NAME/documentserver/server/FileConverter
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/web-apps \
    /var/www/$COMPANY_NAME/documentserver/web-apps
COPY --from=ds-service \
    /usr/lib64/libgraphics.so \
    /usr/lib64/libdoctrenderer.so \
    /usr/lib64/libkernel.so \
    /usr/lib64/libkernel_network.so \
    /usr/lib64/libicudata.so.58 \
    /usr/lib64/libicuuc.so.58 \
    /usr/lib64/libDjVuFile.so \
    /usr/lib64/libEpubFile.so \
    /usr/lib64/libFb2File.so \
    /usr/lib64/libPdfReader.so \
    /usr/lib64/libPdfWriter.so \
    /usr/lib64/libHtmlFile2.so \
    /usr/lib64/libHtmlRenderer.so \
    /usr/lib64/libUnicodeConverter.so \
    /usr/lib64/libXpsFile.so \
    /usr/lib64/
COPY docker-entrypoint.sh /usr/local/bin/
RUN mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder && \
    chown -R ds:ds /var/lib/$COMPANY_NAME/documentserver
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/FileConverter/converter

FROM statsd/statsd AS metrics
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/Metrics/config/config.js /usr/src/app/config.js

FROM postgres:9.5 AS db
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/schema/postgresql/createdb.sql /docker-entrypoint-initdb.d/
