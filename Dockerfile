FROM centos:7 AS ds-base

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ARG PRODUCT_URL=http://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver-ie.x86_64.rpm

ENV COMPANY_NAME=$COMPANY_NAME

RUN yum -y install \
        epel-release \
        curl \
        sudo && \
    yum -y updateinfo && \
    groupadd --system --gid 101 ds && \
    useradd --system -g ds --no-create-home --shell /sbin/nologin --uid 101 ds && \
    yum -y install \
        gettext \
        $PRODUCT_URL \
        nc && \
    chmod a+r /etc/$COMPANY_NAME/documentserver*/*.json && \
    chmod a+r /etc/$COMPANY_NAME/documentserver/log4js/*.json && \
    sed 's,\(listen.\+:\)\([0-9]\+\)\(.*;\),'"\18888\3"',' \
        -i /etc/nginx/conf.d/ds.conf && \
    sed '/error_log.*/d' -i /etc/nginx/includes/ds-common.conf && \
    chmod 755 /var/log/nginx && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    yum clean all && \
    rm -rf /var/tmp/yum-*

COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/includes/http-common.conf /etc/nginx/includes/http-common.conf
COPY config/nginx/includes/http-upstream.conf /etc/nginx/includes/http-upstream.conf
COPY start-helper.sh /app/start-helper.sh

RUN chmod a+x /app/*.sh && \
    mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder \
        /var/www/$COMPANY_NAME/documentserver-example/public/files && \
    documentserver-generate-allfonts.sh true

VOLUME /var/lib/$COMPANY_NAME /var/www/$COMPANY_NAME/documentserver-example/public/files

USER 101

FROM ds-base AS proxy
ENV DOCSERVICE_HOST_PORT=localhost:8000 \
    SPELLCHECKER_HOST_PORT=localhost:8080 \
    EXAMPLE_HOST_PORT=localhost:3000
EXPOSE 8888
ENTRYPOINT envsubst < /etc/nginx/includes/http-upstream.conf > /tmp/http-upstream.conf && exec nginx -g 'daemon off;'

FROM ds-base as ds-service
ENV NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver

FROM ds-service AS docservice
EXPOSE 8000
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/DocService/docservice

FROM ds-service AS converter
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/FileConverter/converter

FROM centos:7 AS spellchecker
LABEL maintainer Ascensio System SIA <support@onlyoffice.com>
ARG COMPANY_NAME=onlyoffice
ENV COMPANY_NAME=$COMPANY_NAME \
    NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver
EXPOSE 8080
COPY --from=ds-base /etc/$COMPANY_NAME/documentserver/log4js /etc/$COMPANY_NAME/documentserver/log4js
COPY --from=ds-base /etc/$COMPANY_NAME/documentserver/*.json /etc/$COMPANY_NAME/documentserver/
COPY --from=ds-base /var/www/$COMPANY_NAME/documentserver/server/SpellChecker /var/www/$COMPANY_NAME/documentserver/server/SpellChecker
COPY start-helper.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver/server/SpellChecker/spellchecker

FROM statsd/statsd AS metrics
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-base /var/www/$COMPANY_NAME/documentserver/server/Metrics/config/config.js /usr/src/app/config.js

FROM centos:7 AS example
ARG COMPANY_NAME=onlyoffice
ENV COMPANY_NAME=$COMPANY_NAME \
    NODE_ENV=production-linux \
    NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver-example
EXPOSE 8000
COPY --from=ds-base /etc/$COMPANY_NAME/documentserver-example /etc/$COMPANY_NAME/documentserver-example
COPY --from=ds-base /var/www/$COMPANY_NAME/documentserver-example /var/www/$COMPANY_NAME/documentserver-example
COPY example-docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod a+x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT docker-entrypoint.sh /var/www/$COMPANY_NAME/documentserver-example/example

FROM postgres:9.5 AS db
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-base /var/www/$COMPANY_NAME/documentserver/server/schema/postgresql/createdb.sql /docker-entrypoint-initdb.d/