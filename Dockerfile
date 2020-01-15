FROM centos:7

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

ARG COMPANY_NAME=onlyoffice
ARG PRODUCT_NAME=documentserver

ENV COMPANY_NAME=$COMPANY_NAME

RUN yum -y install \
        http://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm && \
    yum -y install \
        epel-release \
        sudo && \
    yum -y updateinfo && \
    yum -y install \
        $COMPANY_NAME-$PRODUCT_NAME \
        nc

COPY config /app/ds/setup/config/
COPY run-document-server.sh /app/ds/run-document-server.sh

EXPOSE 8000 8080 3000

VOLUME /var/log/$COMPANY_NAME /var/lib/$COMPANY_NAME /var/www/$COMPANY_NAME/Data /usr/share/fonts/truetype/custom

ENTRYPOINT /app/ds/run-document-server.sh
