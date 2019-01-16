FROM centos:7

LABEL maintainer Ascensio System SIA <support@onlyoffice.com>

RUN yum -y install \
        http://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm && \
    yum -y install \
        epel-release \
        sudo && \
    yum -y updateinfo && \
    yum -y install \
        onlyoffice-documentserver \
        nc && \
    npm install -g json

COPY config /app/onlyoffice/setup/config/
COPY run-document-server.sh /app/onlyoffice/run-document-server.sh

EXPOSE 8000 8080 3000

VOLUME /var/log/onlyoffice /var/lib/onlyoffice /var/www/onlyoffice/Data /usr/share/fonts/truetype/custom

ENTRYPOINT /app/onlyoffice/run-document-server.sh
