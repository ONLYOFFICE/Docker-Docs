* [Overview](#overview)
* [Functionality](#functionality)
* [Recommended System Requirements](#recommended-system-requirements)
* [Running ONLYOFFICE Docs](#running-onlyoffice-docs)
* [Project Information](#project-information)
* [User Feedback and Support](#user-feedback-and-support)

## Overview

ONLYOFFICE Docs is an online office suite comprising viewers and editors for texts, spreadsheets and presentations, fully compatible with Office Open XML formats: .docx, .xlsx, .pptx and enabling collaborative editing in real time.

## Functionality ##
* ONLYOFFICE Document Editor
* ONLYOFFICE Spreadsheet Editor
* ONLYOFFICE Presentation Editor
* ONLYOFFICE Documents application for iOS
* Collaborative editing
* Hieroglyph support
* Support for all the popular formats: DOC, DOCX, TXT, ODT, RTF, ODP, EPUB, ODS, XLS, XLSX, CSV, PPTX, HTML

Integrating it with ONLYOFFICE Community Server you will be able to:
* view and edit files stored on Drive, Box, Dropbox, OneDrive, OwnCloud connected to ONLYOFFICE;
* share files;
* embed documents on a website;
* manage access rights to documents.

## Recommended System Requirements

* **RAM**: 4 GB or more
* **CPU**: dual-core 2 GHz or higher
* **Swap**: at least 2 GB
* **HDD**: at least 2 GB of free space
* **Distribution**: 64-bit Red Hat, CentOS or other compatible distributive with kernel version 3.8 or later, 64-bit Debian, Ubuntu or other compatible distributive with kernel version 3.8 or later
* **Docker**: version 1.9.0 or later

## Running ONLYOFFICE Docs


First, you have to install [docker-compose](https://docs.docker.com/compose/install "docker-compose"). Assuming you have docker-compose installed, execute the following command:

```bash
docker-compose up -d
```

To stop ONLYOFFICE Docs type:

```bash
docker-compose down
```

#### Available Configuration Parameters

ONLYOFFICE Docs consits of set of images
- onlyoffice/docs-proxy
- onlyoffice/docs-docservice
- onlyoffice/docs-converter
- onlyoffice/docs-spellchecker
- onlyoffice/example

Each of them can be configured by environment variables. Please refer to your docker orchestrating system for details.

Below is the complete list of parameters for `onlyoffice/docs-proxy`.
- **DOCSERVICE_HOST_PORT**: Defaults to `localhost:8000`.
- **SPELLCHECKER_HOST_PORT**: Defaults to `localhost:8080`.
- **EXAMPLE_HOST_PORT**: Defaults to `localhost:3000`.
- **NGINX_ACCESS_LOG**: Defines the nginx config [access_log](https://nginx.org/ru/docs/http/ngx_http_log_module.html#access_log) directive. Defaults to `off`.
- **NGINX_GZIP_PROXIED**: Defines the nginx config [gzip_proxied](https://nginx.org/ru/docs/http/ngx_http_gzip_module.html#gzip_proxied) directive. Defaults to `off`.
- **NGINX_WORKER_CONNECTIONS**: Defines the nginx config [worker_connections](https://nginx.org/en/docs/ngx_core_module.html#worker_connections) directive. Defaults to `4096`.

Below is the complete list of parameters for `onlyoffice/docs-docservice`, `onlyoffice/docs-converter`, `onlyoffice/docs-spellchecker`.

- **DB_HOST**: The IP address or the name of the host where the PostgreSQL server is running.
- **DB_PORT**: The PostgreSQL server port number.
- **DB_NAME**: The name of a PostgreSQL database to be created on the image startup.
- **DB_USER**: The new user name with superuser permissions for the PostgreSQL account.
- **DB_PWD**: The password set for the PostgreSQL account.
- **AMQP_PROTO**: The protocol for the commection to AMQP server.
- **AMQP_USER**: The user name for the AMQP server account.
- **AMQP_PWD**: The password set for the AMQP server account.
- **AMQP_HOST**: The IP address or the name of the host where the AMQP server is running.
- **REDIS_SERVER_HOST**: The IP address or the name of the host where the Redis server is running.
- **REDIS_SERVER_PORT**:  The Redis server port number.
- **JWT_ENABLED**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Defaults to `false`.
- **JWT_SECRET**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Defaults to `secret`.
- **JWT_HEADER**: Defines the http header that will be used to send the JSON Web Token. Defaults to `Authorization`.
- **JWT_IN_BODY**: Specifies the enabling the token validation in the request body to the ONLYOFFICE Docs. Defaults to `false`.
- **LOG_LEVEL**: Defines the type and severity of a logged event. Default to `WARN`. Possible values are `ALL`, `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `MARK`, `OFF`.
- **METRICS_ENABLED**: Specifies the enabling StatsD for ONLYOFFICE Docs. Defaults to `false`.
- **METRICS_HOST**: Defines StatsD listening host. Defaults to `localhost`.
- **METRICS_PORT**: Defines StatsD listening port. Defaults to `8125`.
- **METRICS_PREFIX**: Defines StatsD metrics prefix for backend services. Defaults to `ds.`.

Below is the complete list of parameters for `onlyoffice/docs-example`.
- **JWT_ENABLED**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Defaults to `false`.
- **JWT_SECRET**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Defaults to `secret`.
- **JWT_HEADER**: Defines the http header that will be used to send the JSON Web Token. Defaults to `Authorization`.

## Project Information

Official website: [http://www.onlyoffice.org](http://onlyoffice.org "http://www.onlyoffice.org")

Code repository: [https://github.com/ONLYOFFICE/DocumentServer](https://github.com/ONLYOFFICE/DocumentServer "https://github.com/ONLYOFFICE/DocumentServer")

License: [GNU AGPL v3.0](https://help.onlyoffice.com/products/files/doceditor.aspx?fileid=4358397&doc=K0ZUdlVuQzQ0RFhhMzhZRVN4ZFIvaHlhUjN2eS9XMXpKR1M5WEppUk1Gcz0_IjQzNTgzOTci0 "GNU AGPL v3.0")

SaaS version: [http://www.onlyoffice.com](http://www.onlyoffice.com "http://www.onlyoffice.com")

## User Feedback and Support

If you have any problems with or questions about this image, please visit our official forum to find answers to your questions: [dev.onlyoffice.org][1] or you can ask and answer ONLYOFFICE development questions on [Stack Overflow][2].

  [1]: http://dev.onlyoffice.org
  [2]: http://stackoverflow.com/questions/tagged/onlyoffice
