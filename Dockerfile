ARG POSTGRES_VERSION="12"
ARG MYSQL_VERSION="latest"
ARG MARIADB_VERSION="latest"

FROM amazonlinux:2 AS ds-base

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ARG DS_VERSION_HASH
ENV COMPANY_NAME=$COMPANY_NAME \
    APPLICATION_NAME=$COMPANY_NAME \
    DS_VERSION_HASH=$DS_VERSION_HASH \
    NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver

RUN yum install sudo -y && \
    yum install shadow-utils -y && \
    amazon-linux-extras install epel -y && \
    yum install procps-ng tar wget -y && \
    wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_$(uname -m) && \
    chmod +x /usr/local/bin/dumb-init && \
    groupadd --system --gid 101 ds && \
    useradd --system -g ds --no-create-home --shell /sbin/nologin --uid 101 ds && \
    rm -f /var/log/*log

FROM python:2.7 AS redis-lib
RUN pip install redis==3.5.3

FROM ds-base AS ds-service
ARG TARGETARCH
ARG DS_VERSION_HASH
ARG PRODUCT_EDITION=
ARG RELEASE_VERSION
ARG PRODUCT_BASEURL=https://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver
ARG PRODUCT_URL=${PRODUCT_BASEURL}${PRODUCT_EDITION}${RELEASE_VERSION}.${TARGETARCH}.rpm
ENV TARGETARCH=$TARGETARCH \
    DS_VERSION_HASH=$DS_VERSION_HASH
WORKDIR /ds
RUN useradd --no-create-home --shell /sbin/nologin nginx && \
    yum -y updateinfo && \
    yum -y install cabextract fontconfig xorg-x11-font-utils xorg-x11-server-utils rpm2cpio && \
    rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm && \
    PRODUCT_URL=$(echo $PRODUCT_URL | sed "s/"$TARGETARCH"/"$(uname -m)"/g") && \
    PACKAGE_NAME=$(basename "$PRODUCT_URL") && \
    wget $PRODUCT_URL && \
    rpm -ivh $PACKAGE_NAME --noscripts --nodeps && \
    rpm2cpio $PACKAGE_NAME | cpio -idmv ./usr/lib64/* && \
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
    fonts/ \
    /var/www/$COMPANY_NAME/documentserver/core-fonts/custom/
COPY --chown=ds:ds \
    plugins/ \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins/
RUN documentserver-generate-allfonts.sh true && \
    documentserver-flush-cache.sh -h $DS_VERSION_HASH -r false && \
    documentserver-pluginsmanager.sh -r false \
    --update=\"/var/www/$COMPANY_NAME/documentserver/sdkjs-plugins/plugin-list-default.json\"

FROM ds-base AS proxy
ENV DOCSERVICE_HOST_PORT=localhost:8000 \
    EXAMPLE_HOST_PORT=localhost:3000 \
    NGINX_ACCESS_LOG=off \
    NGINX_GZIP_PROXIED=off \
    NGINX_CLIENT_MAX_BODY_SIZE=100m \
    NGINX_WORKER_CONNECTIONS=4096 \
    NGINX_WORKER_PROCESSES=1
EXPOSE 8888
RUN yum -y updateinfo && \
    yum -y install gettext nginx httpd-tools && \
    yum clean all && \
    rm -f /var/log/*log
COPY --chown=ds:ds config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --chown=ds:ds proxy-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY --chown=ds:ds --chmod=644 --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/nginx/ds.conf \
    /etc/nginx/conf.d/
COPY --chown=ds:ds --chmod=644 --from=ds-service \
    /etc/$COMPANY_NAME/documentserver*/nginx/includes/*.conf \
    /etc/nginx/includes/ds-cache.conf \
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
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/document-templates/new \
    /var/www/$COMPANY_NAME/documentserver/document-templates/new
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
    sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /etc/nginx/nginx.conf && \
    sed -i 's/etc\/nginx/tmp\/proxy_nginx/g' /etc/nginx/conf.d/ds.conf && \
    sed 's/\(X-Forwarded-For\).*/\1 example.com;/' -i /etc/nginx/includes/ds-example.conf && \
    sed 's/\(index\).*/\1 k8s.html;/' -i /etc/nginx/includes/ds-example.conf && \
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
ENTRYPOINT docker-entrypoint.sh

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
    /var/www/$COMPANY_NAME/documentserver/web-apps/apps/common/main/resources/themes \
    /var/www/$COMPANY_NAME/documentserver/web-apps/apps/common/main/resources/themes
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/DocService \
    /var/www/$COMPANY_NAME/documentserver/server/DocService
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/info \
    /var/www/$COMPANY_NAME/documentserver/server/info
COPY --chown=ds:ds --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/web-apps/apps/api/wopi \
    /var/www/$COMPANY_NAME/documentserver/web-apps/apps/api/wopi
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/document-templates/new \
    /var/www/$COMPANY_NAME/documentserver/document-templates/new
COPY  --from=redis-lib \
    /usr/local/lib/python2.7/site-packages/redis \
    /usr/lib/python2.7/site-packages/redis
COPY  --from=redis-lib \
    /usr/local/lib/python2.7/site-packages/redis-3.5.3.dist-info \
    /usr/lib/python2.7/site-packages/redis-3.5.3.dist-info
COPY docker-entrypoint.sh /usr/local/bin/
USER ds
ENTRYPOINT dumb-init docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/DocService/docservice
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
    /var/www/$COMPANY_NAME/documentserver/document-templates/new \
    /var/www/$COMPANY_NAME/documentserver/document-templates/new
COPY --from=ds-service \
    /ds/usr/lib64/* \
    /usr/lib64/
COPY docker-entrypoint.sh /usr/local/bin/
RUN mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder && \
    chown -R ds:ds /var/lib/$COMPANY_NAME/documentserver
USER ds
ENTRYPOINT dumb-init docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/FileConverter/converter

FROM node:20-alpine3.19 AS example
LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/onlyoffice/documentserver-example/

WORKDIR /var/www/onlyoffice/documentserver-example/

RUN apk update && \
    apk add git && \
    git clone \
      --depth 1 \
      --recurse-submodules \
      https://github.com/ONLYOFFICE/document-server-integration.git && \
    mkdir -p /var/www/onlyoffice/documentserver-example && \
    cp -r ./document-server-integration/web/documentserver-example/nodejs/. \
      /var/www/onlyoffice/documentserver-example/ && \
    rm -rf ./document-server-integration && \
    addgroup -S -g 1001 ds && \
    adduser \
      -S \
      -G ds \
      -D \
      -h /var/www/onlyoffice/documentserver-example \
      -s /sbin/nologin \
      -u 1001 ds && \
    chown -R ds:ds /var/www/onlyoffice/documentserver-example/ && \
    mkdir -p /var/lib/onlyoffice/documentserver-example/ && \
    chown -R ds:ds /var/lib/onlyoffice/ && \
    mv files /var/lib/onlyoffice/documentserver-example/ && \
    mkdir -p /etc/onlyoffice/documentserver-example/ && \
    chown -R ds:ds /etc/onlyoffice/ && \
    mv config/* /etc/onlyoffice/documentserver-example/ && \
    npm install

EXPOSE 3000

USER ds

ENTRYPOINT /var/www/onlyoffice/documentserver-example/docker-entrypoint.sh npm start

FROM python:3.11 AS builder
RUN pip install redis psycopg2  PyMySQL pika python-qpid-proton func_timeout requests kubernetes flask
FROM python:3.11-slim AS utils
ARG DS_VERSION_HASH
ENV DS_VERSION_HASH=$DS_VERSION_HASH
COPY --from=ds-base /usr/local/bin/dumb-init /usr/local/bin/dumb-init
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
RUN apt update && \
    apt-get install -y wget gnupg2 lsb-release && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt install -y postgresql-client-17 default-mysql-client curl wget jq && \
    curl -LO \
      https://storage.googleapis.com/kubernetes-release/release/`curl \
      -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    groupadd --system -g 1006 ds && \
    useradd --system -g ds -d /home/ds -s /bin/bash -u 101 ds && \
    mkdir /scripts && \
    chown -R ds:ds /scripts && \
    chmod +x /usr/local/bin/dumb-init
USER ds

FROM statsd/statsd AS metrics
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/Metrics/config/config.js /usr/src/app/config.js

FROM postgres:$POSTGRES_VERSION AS db
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/schema/postgresql/createdb.sql /docker-entrypoint-initdb.d/

FROM mysql:$MYSQL_VERSION AS mysqldb
ARG COMPANY_NAME=onlyoffice
COPY --chmod=777 --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/schema/mysql/createdb.sql /docker-entrypoint-initdb.d/

FROM mariadb:$MARIADB_VERSION AS db-mariadb
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/schema/mysql/createdb.sql /docker-entrypoint-initdb.d/
