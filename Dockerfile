FROM centos:7

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ARG PRODUCT_URL=http://download.onlyoffice.com/install/documentserver/linux/onlyoffice-documentserver-ie.x86_64.rpm

ENV COMPANY_NAME=$COMPANY_NAME

RUN yum -y install \
        epel-release \
        curl \
        sudo && \
    curl -sL https://rpm.nodesource.com/setup_8.x | bash - && \
    yum -y updateinfo && \
    groupadd --system --gid 101 ds && \
    useradd --system -g ds --no-create-home --shell /sbin/nologin --uid 101 ds && \
    yum -y install \
        $PRODUCT_URL \
        nc && \
    chmod a+r /etc/$COMPANY_NAME/documentserver*/*.json && \
    chmod a+r /etc/$COMPANY_NAME/documentserver/log4js/*.json && \
    sed '/user=.*/d' -i /etc/supervisord.d/ds-*.ini && \
    sed 's,\(listen.\+:\)\([0-9]\+\)\(.*;\),'"\18888\3"',' \
        -i /etc/nginx/conf.d/ds.conf

RUN chmod 755 /var/log/nginx && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY config/nginx/includes/http-common.conf /etc/nginx/includes/http-common.conf
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/supervisor/supervisord.conf /etc/supervisord.conf
COPY run-document-server.sh /app/ds/run-document-server.sh

EXPOSE 8000 8080 3000 8888

VOLUME /var/log/$COMPANY_NAME /var/lib/$COMPANY_NAME /var/www/onlyoffice/$COMPANY_NAME-example/public/files /var/log/nginx

USER 101

ENTRYPOINT /app/ds/run-document-server.sh
