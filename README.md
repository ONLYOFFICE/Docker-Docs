## Overview
[![Multi-arch build](https://github.com/ONLYOFFICE/Docker-Docs/actions/workflows/build.yaml/badge.svg)](https://github.com/ONLYOFFICE/Docker-Docs/actions/workflows/build.yaml)

ONLYOFFICE Docs is an online office suite comprising viewers and editors for texts, spreadsheets and presentations and enabling collaborative editing in real time. The suite provides maximum compatibility with Office Open XML formats: .docx, .xlsx, .pptx. 

This set of images contain the same functionality as [Document Server](https://github.com/ONLYOFFICE/DocumentServer) but internal services are decoupled into multiple containers.

This repository is intended for images used in the Document Server [Helm package for Kubernetes](https://github.com/ONLYOFFICE/Kubernetes-Docs), which allows deploying it into a cluster.

## Functionality

* ONLYOFFICE Document Editor
* ONLYOFFICE Spreadsheet Editor
* ONLYOFFICE Presentation Editor
* Collaborative editing
* Hieroglyph support
* Support for all the popular formats: DOC, DOCX, TXT, ODT, RTF, ODP, EPUB, ODS, XLS, XLSX, CSV, PPTX, HTML

By default, ONLYOFFICE Docs includes only editors without any document management system. ONLYOFFICE Docs can be used as a part of [ONLYOFFICE Workspace](#onlyoffice-workspace) or with third-party sync&share solutions (e.g. Nextcloud, ownCloud, Seafile) to enable collaborative editing within their interface. 

ONLYOFFICE Docs has three editions - [Community, Enterprise, and Developer](https://github.com/ONLYOFFICE/DocumentServer#onlyoffice-document-server-editions). Clustering is available only for commercial builds (Enterprise and Developer Edition).

## Recommended system requirements

* **RAM**: 4 GB or more
* **CPU**: dual-core 2 GHz or higher
* **Swap**: at least 2 GB
* **HDD**: at least 2 GB of free space
* **Distribution**: 64-bit Red Hat, CentOS or other compatible distributive with kernel version 3.8 or later, 64-bit Debian, Ubuntu or other compatible distributive with kernel version 3.8 or later
* **Docker**: version 1.9.0 or later
* **Docker-compose**: version 1.28.0 or later

## Building ONLYOFFICE Docs

### Cloning this repository

To clone this repository, run the following command:

```bash
git clone https://github.com/ONLYOFFICE/Docker-Docs.git
```

Go to the Docker-Docs directory.

### Adding custom Fonts (optional)

To add your custom fonts to the images, add your custom fonts to the `fonts` directory.

### Adding Plugins (optional)

To add plugins to the images, add the folder with the plugin code to the `plugins` directory.

### Building images

To build images, please follow these steps

#### 1. Change the variables

Change the value of the `ACCOUNT_NAME` variable in the `.env` file. It must contain the account name in Docker Hub. If necessary, change the values of the variables `PREFIX_NAME` and `DOCKER_TAG` in the `.env` file.

Also, depending on the solution type, specify the required value for the `PRODUCT_EDITION` variable in the `.env` file.

Possible values:
  - Nothing is specified. For the open-source community version. Default,
  - `-de`. For commercial Developer Edition,
  - `-ee`. For commercial Enterprise Edition.

#### 2. Run the build

To start the build, run the following command:

```bash
./build.sh
```

#### 3. Publish the images to the image repository

Log in to the local host:

```bash
docker login
```

To publish the images, run the following command:

```bash
docker-compose push
```

## Running ONLYOFFICE Docs

Execute the following command:

```bash
docker-compose up -d
```

To stop ONLYOFFICE Docs, type:

```bash
docker-compose down
```

#### Services scaling

Converter and docservice can be scaled by changing the [replicas](https://github.com/ONLYOFFICE/Docker-Docs/blob/feature/scale-capability/docker-compose.yml#L25) parameter in the compose file. 

You can also set the number of replicas manualy when you deploy services with compose, for example:

```
docker compose up -d --scale docservice=3
```

NOTE: If you wanna scale your container on runtime it is necessary to deploy services through docker swarm. After that you can scale in runtime, for example:

```
docker service scale <deploy_name>_docservice=2
```

#### Available сonfiguration parameters

ONLYOFFICE Docs consists of set of images:

- onlyoffice/docs-proxy
- onlyoffice/docs-docservice
- onlyoffice/docs-converter
- onlyoffice/docs-example

Each of them can be configured by environment variables. Please refer to your docker orchestrating system for details.

Below is the complete list of parameters for `onlyoffice/docs-proxy`.
- **DOCSERVICE_HOST_PORT**: Defaults to `localhost:8000`.
- **EXAMPLE_HOST_PORT**: Defaults to `localhost:3000`.
- **NGINX_ACCESS_LOG**: Defines the nginx config [access_log](https://nginx.org/ru/docs/http/ngx_http_log_module.html#access_log) directive. Defaults to `off`.
- **NGINX_GZIP_PROXIED**: Defines the nginx config [gzip_proxied](https://nginx.org/ru/docs/http/ngx_http_gzip_module.html#gzip_proxied) directive. Defaults to `off`.
- **NGINX_WORKER_CONNECTIONS**: Defines the nginx config [worker_connections](https://nginx.org/en/docs/ngx_core_module.html#worker_connections) directive. Defaults to `4096`.
- **SECURE_LINK_SECRET**: Defines secret for the nginx config directive [secure_link_md5](http://nginx.org/ru/docs/http/ngx_http_secure_link_module.html#secure_link_md5). Defaults to `verysecretstring`.
- **INFO_ALLOWED_IP**: Defines ip addresses for accessing the info page. You can specify multiple values separated by a space.

Below is the complete list of parameters for `onlyoffice/docs-proxy`, `onlyoffice/docs-docservice`.
- **DEFAULT_PLUGINS_REMOVE**: Defines the default [plugins](https://helpcenter.onlyoffice.com/onlyoffice-editors/onlyoffice-document-editor/ProgramInterface/PluginsTab.aspx) that need to be removed. You can specify multiple values separated by a space, or if you need to remove all default plugins, you can pass `allPlugins` as the value.

Below is the complete list of parameters for `onlyoffice/docs-docservice`, `onlyoffice/docs-converter`.
- **DB_TYPE**: The database type. Supported values are `postgres`, `mariadb` or `mysql`. Defaults to `postgres`.
- **DB_HOST**: The IP address or the name of the host where the PostgreSQL server is running.
- **DB_PORT**: The PostgreSQL server port number. Default to `5432`.
- **DB_NAME**: The name of a PostgreSQL database to be created on the image startup.
- **DB_USER**: The new user name with superuser permissions for the PostgreSQL account.
- **DB_PWD**: The password set for the PostgreSQL account.
- **AMQP_TYPE**: Defines the message broker type. Defaults to `rabbitmq`. Possible values are `rabbitmq` or `activemq`.
- **AMQP_PROTO**: The protocol for the connection to AMQP server. Default to `amqp`. Possible values are `amqp`, `amqps`.
- **AMQP_USER**: The username for the AMQP server account.
- **AMQP_PWD**: The password set for the AMQP server account.
- **AMQP_HOST**: The IP address or the name of the host where the AMQP server is running.
- **AMQP_PORT**: The port for the connection to AMQP server. Default to `5672`.
- **AMQP_VHOST**: The virtual host for the connection to AMQP server. Default to `/`.
- **REDIS_SERVER_HOST**: The IP address or the name of the host where the Redis server is running.
- **REDIS_SERVER_PORT**:  The Redis server port number. Default to `6379`.
- **JWT_ENABLED**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Common for inbox and outbox requests. Defaults to `true`.
- **JWT_ENABLED_INBOX**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs only for inbox requests. Default, the value of the variable `JWT_ENABLED` is used.
- **JWT_ENABLED_OUTBOX**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs only for outbox requests. Default, the value of the variable `JWT_ENABLED` is used.
- **JWT_SECRET**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Common for inbox and outbox requests. Defaults to `secret`.
- **JWT_SECRET_INBOX**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs only for inbox requests. Default, the value of the variable `JWT_SECRET` is used.
- **JWT_SECRET_OUTBOX**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs only for outbox requests. Default, the value of the variable `JWT_SECRET` is used.
- **JWT_HEADER**: Defines the http header that will be used to send the JSON Web Token. Common for inbox and outbox requests. Defaults to `Authorization`.
- **JWT_HEADER_INBOX**: Defines the http header that will be used to send the JSON Web Token only for inbox requests. Default, the value of the variable `JWT_HEADER` is used.
- **JWT_HEADER_OUTBOX**: Defines the http header that will be used to send the JSON Web Token only for outbox requests. Default, the value of the variable `JWT_HEADER` is used.
- **JWT_IN_BODY**: Specifies the enabling the token validation in the request body to the ONLYOFFICE Docs. Defaults to `false`.
- **LOG_LEVEL**: Defines the type and severity of a logged event. Default to `WARN`. Possible values are `ALL`, `TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`, `MARK`, `OFF`.
- **LOG_TYPE**: Defines the format of a logged event. Default to `pattern`. Possible values are `pattern`, `json`, `basic`, `coloured`, `messagePassThrough`, `dummy`.
- **LOG_PATTERN**: Defines the log [pattern](https://github.com/log4js-node/log4js-node/blob/master/docs/layouts.md#pattern-format) if `LOG_TYPE=pattern`. Default to `[%d] [%p] %c - %.10000m`.
- **METRICS_ENABLED**: Specifies the enabling StatsD for ONLYOFFICE Docs. Defaults to `false`.
- **METRICS_HOST**: Defines StatsD listening host. Defaults to `localhost`.
- **METRICS_PORT**: Defines StatsD listening port. Defaults to `8125`.
- **METRICS_PREFIX**: Defines StatsD metrics prefix for backend services. Defaults to `ds.`.

Below is the complete list of parameters for `onlyoffice/docs-example`.
- **DS_URL**: Specifies ONLYOFFICE Docs server address. Defaults to `/`. You have specyfing this field to correct work ONLYOFFICE Docs Example. Example `http://onlyoffice-docs-address/`.
- **JWT_ENABLED**: Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Defaults to `false`.
- **JWT_SECRET**: Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Defaults to `secret`.
- **JWT_HEADER**: Defines the http header that will be used to send the JSON Web Token. Defaults to `Authorization`.
- **WOPI_ENABLED**: Specifies the enabling the wopi handlers. Defaults to `false`.

## Project Information

Official website: [https://www.onlyoffice.com/](https://www.onlyoffice.com/ "https://www.onlyoffice.com/")

Code repository: [https://github.com/ONLYOFFICE/DocumentServer](https://github.com/ONLYOFFICE/DocumentServer "https://github.com/ONLYOFFICE/DocumentServer")

License: [GNU AGPL v3.0](https://help.onlyoffice.com/products/files/doceditor.aspx?fileid=4358397&doc=K0ZUdlVuQzQ0RFhhMzhZRVN4ZFIvaHlhUjN2eS9XMXpKR1M5WEppUk1Gcz0_IjQzNTgzOTci0 "GNU AGPL v3.0")

ONLYOFFICE Docs on official website: [http://www.onlyoffice.com/office-suite.aspx](http://www.onlyoffice.com/office-suite.aspx "http://www.onlyoffice.com/office-suite.aspx")

List of available integrations: [http://www.onlyoffice.com/all-connectors.aspx](http://www.onlyoffice.com/all-connectors.aspx "http://www.onlyoffice.com/all-connectors.aspx")

## ONLYOFFICE Workspace

ONLYOFFICE Docs packaged as Document Server is a part of **ONLYOFFICE Workspace** that also includes ONLYOFFICE Groups (packaged as [Community Server](https://github.com/ONLYOFFICE/CommunityServer "Community Server")), [Mail Server](https://github.com/ONLYOFFICE/Docker-MailServer "Mail Server"), Control Panel and Talk (instant messaging app). 

## User feedback and support

If you have any problems with or questions about this image, please visit our official forum to find answers to your questions: [forum.onlyoffice.com][1] or you can ask and answer ONLYOFFICE development questions on [Stack Overflow][2].

  [1]: https://forum.onlyoffice.com
  [2]: http://stackoverflow.com/questions/tagged/onlyoffice
