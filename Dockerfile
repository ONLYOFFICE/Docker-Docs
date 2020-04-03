FROM centos:7 AS ds-base

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ARG PRODUCT_URL=http://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver-ie.x86_64.rpm

ENV COMPANY_NAME=$COMPANY_NAME
ENV NODE_ENV=production-linux
ENV NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver

RUN yum -y install \
        epel-release \
        curl \
        sudo && \
    yum -y updateinfo && \
    groupadd --system --gid 101 ds && \
    useradd --system -g ds --no-create-home --shell /sbin/nologin --uid 101 ds && \
    yum -y install \
        $PRODUCT_URL \
        nc && \
    chmod a+r /etc/$COMPANY_NAME/documentserver*/*.json && \
    chmod a+r /etc/$COMPANY_NAME/documentserver/log4js/*.json && \
    sed 's,\(listen.\+:\)\([0-9]\+\)\(.*;\),'"\18888\3"',' \
        -i /etc/nginx/conf.d/ds.conf && \
    sed '/error_log.*/d' -i /etc/nginx/includes/ds-common.conf

RUN chmod 755 /var/log/nginx && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    # sed 's,\(include\s\+\)\(\/etc\/nginx\/includes\)\(\/http-common\.conf\),\1/tmp\3,' \
    #     -i /etc/nginx/conf.d/ds.conf && \
    # sed 's,\(server\s\+\)\(localhost:8000\)\(;\),\1$DOCSERVICE_HOST_PORT\3,' \
    #     -i /etc/nginx/includes/http-common.conf && \
    # sed 's,\(server\s\+\)\(localhost:8080\)\(;\),\1$SPELLCHECKER_HOST_PORT\3,' \
    #     -i /etc/nginx/includes/http-common.conf && \
    # sed 's,\(server\s\+\)\(localhost:3000\)\(;\),\1$EXAMPLE_HOST_PORT\3,' \
    #     -i /etc/nginx/includes/http-common.conf && \
    yum -y install gettext

COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/includes/http-common.conf /etc/nginx/includes/http-common.conf
COPY config/nginx/includes/http-upstream.conf /etc/nginx/includes/http-upstream.conf
COPY start-helper.sh /app/start-helper.sh
RUN chmod a+x /app/start-helper.sh && \
    mkdir -p \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/cache/files \
        /var/lib/$COMPANY_NAME/documentserver/App_Data/docbuilder \
        /var/www/$COMPANY_NAME/documentserver-example/public/files && \
    documentserver-generate-allfonts.sh true

VOLUME /var/lib/$COMPANY_NAME /var/www/$COMPANY_NAME/documentserver-example/public/files

USER 101

FROM ds-base AS proxy
EXPOSE 8888
ENTRYPOINT envsubst < /etc/nginx/includes/http-upstream.conf > /tmp/http-upstream.conf && exec nginx -g 'daemon off;'

FROM ds-base AS docservice
EXPOSE 8000
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/DocService/docservice

FROM ds-base AS converter
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/FileConverter/converter

FROM ds-base AS spellchecker
EXPOSE 8080
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/SpellChecker/spellchecker

FROM ds-base AS metrics
CMD [""]
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver/server/Metrics/metrics /var/www/$COMPANY_NAME/documentserver/server/Metrics/metrics/config/config.js

FROM ds-base AS example
ENV NODE_CONFIG_DIR=/etc/$COMPANY_NAME/documentserver-example
ENTRYPOINT /app/start-helper.sh /var/www/$COMPANY_NAME/documentserver-example/example

FROM postgres:9.5 AS db
ARG COMPANY_NAME=onlyoffice
COPY --from=ds-base /var/www/$COMPANY_NAME/documentserver/server/schema/postgresql/createdb.sql /docker-entrypoint-initdb.d/