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
ARG PRODUCT_URL=http://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver-ie.x86_64.rpm
RUN useradd --no-create-home --shell /sbin/nologin nginx && \
    rpm -ivh $PRODUCT_URL --noscripts --nodeps && \
    chmod a+r /etc/$COMPANY_NAME/documentserver*/*.json && \
    chmod a+r /etc/$COMPANY_NAME/documentserver/log4js/*.json
COPY --chown=ds:ds \
    fonts/* \
    /var/www/$COMPANY_NAME/documentserver/core-fonts/custom/
RUN documentserver-generate-allfonts.sh true

FROM ds-base AS proxy
ENV DOCSERVICE_HOST_PORT=localhost:8000 \
    SPELLCHECKER_HOST_PORT=localhost:8080 \
    EXAMPLE_HOST_PORT=localhost:3000
EXPOSE 8888
RUN yum -y install epel-release sudo && \
    yum -y updateinfo && \
    yum -y install gettext nginx && \
    yum clean all && \
    rm -f /var/log/*log
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=ds-service \
    /etc/onlyoffice/documentserver/nginx/ds.conf \
    /etc/nginx/conf.d/
COPY --from=ds-service \
    /etc/onlyoffice/documentserver/nginx/includes/ds-common.conf \
    /etc/onlyoffice/documentserver/nginx/includes/ds-docservice.conf \
    /etc/onlyoffice/documentserver-example/nginx/includes/ds-example.conf \
    /etc/onlyoffice/documentserver/nginx/includes/ds-spellchecker.conf \
    /etc/nginx/includes/
COPY \
    config/nginx/includes/http-common.conf \
    config/nginx/includes/http-upstream.conf \
    /etc/nginx/includes/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/core-fonts \
    /var/www/$COMPANY_NAME/documentserver/core-fonts
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/fonts \
    /var/www/$COMPANY_NAME/documentserver/fonts
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs \
    /var/www/$COMPANY_NAME/documentserver/sdkjs
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/web-apps \
    /var/www/$COMPANY_NAME/documentserver/web-apps
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver-example/welcome \
    /var/www/$COMPANY_NAME/documentserver-example/welcome
RUN sed 's,\(listen.\+:\)\([0-9]\+\)\(.*;\),'"\18888\3"',' \
        -i /etc/nginx/conf.d/ds.conf && \
    sed '/error_log.*/d' -i /etc/nginx/includes/ds-common.conf && \
    chmod 755 /var/log/nginx && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder && \
    chown -R ds:ds /var/lib/$COMPANY_NAME/documentserver
VOLUME /var/lib/$COMPANY_NAME
USER ds
ENTRYPOINT envsubst < /etc/nginx/includes/http-upstream.conf > /tmp/http-upstream.conf && exec nginx -g 'daemon off;'

FROM ds-base AS docservice
EXPOSE 8000
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/default.json \
    /etc/$COMPANY_NAME/documentserver/production-linux.json \
    /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/log4js/production.json \
    /etc/$COMPANY_NAME/documentserver/log4js/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins \
    /var/www/$COMPANY_NAME/documentserver/sdkjs-plugins
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/DocService \
    /var/www/$COMPANY_NAME/documentserver/server/DocService
COPY docker-entrypoint.sh /usr/local/bin/
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/DocService/docservice

FROM ds-base AS converter
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/default.json \
    /etc/$COMPANY_NAME/documentserver/production-linux.json \
    /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/log4js/production.json \
    /etc/$COMPANY_NAME/documentserver/log4js/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/core-fonts \
    /var/www/$COMPANY_NAME/documentserver/core-fonts
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/fonts \
    /var/www/$COMPANY_NAME/documentserver/fonts
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
    /usr/lib64/libicudata.so.58 \
    /usr/lib64/libicuuc.so.58 \
    /usr/lib64/libDjVuFile.so \
    /usr/lib64/libPdfReader.so \
    /usr/lib64/libPdfWriter.so \
    /usr/lib64/libHtmlFile.so \
    /usr/lib64/libHtmlRenderer.so \
    /usr/lib64/libUnicodeConverter.so \
    /usr/lib64/libXpsFile.so \
    /usr/lib64/
COPY docker-entrypoint.sh /usr/local/bin/
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/FileConverter/converter

FROM ds-base AS spellchecker
EXPOSE 8080
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/default.json \
    /etc/$COMPANY_NAME/documentserver/production-linux.json \
    /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver/log4js/production.json \
    /etc/$COMPANY_NAME/documentserver/log4js/
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver/server/SpellChecker \
    /var/www/$COMPANY_NAME/documentserver/server/SpellChecker
COPY docker-entrypoint.sh /usr/local/bin/
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/SpellChecker/spellchecker

FROM statsd/statsd AS metrics
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/Metrics/config/config.js /usr/src/app/config.js

FROM ds-base AS example
ENV NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver-example
EXPOSE 8000
COPY --from=ds-service \
    /etc/$COMPANY_NAME/documentserver-example \
    /etc/$COMPANY_NAME/documentserver-example
COPY --from=ds-service \
    /var/www/$COMPANY_NAME/documentserver-example \
    /var/www/$COMPANY_NAME/documentserver-example
COPY example-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN mkdir -p /var/lib/$COMPANY_NAME/documentserver-example/files && \
    chown -R ds:ds /var/lib/$COMPANY_NAME/documentserver-example/files
VOLUME /var/lib/$COMPANY_NAME/documentserver-example/files
USER ds
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver-example/example

FROM postgres:9.5 AS db
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-service /var/www/$COMPANY_NAME/documentserver/server/schema/postgresql/createdb.sql /docker-entrypoint-initdb.d/