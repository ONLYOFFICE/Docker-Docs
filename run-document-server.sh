#!/bin/bash

# Define '**' behavior explicitly
shopt -s globstar

APP_DIR="/var/www/onlyoffice/documentserver"
DATA_DIR="/var/www/onlyoffice/Data"
LOG_DIR="/var/log/onlyoffice"
DS_LOG_DIR="${LOG_DIR}/documentserver"
LIB_DIR="/var/lib/onlyoffice"
CONF_DIR="/etc/onlyoffice/documentserver"

ONLYOFFICE_DATA_CONTAINER=${ONLYOFFICE_DATA_CONTAINER:-false}
ONLYOFFICE_DATA_CONTAINER_HOST=${ONLYOFFICE_DATA_CONTAINER_HOST:-localhost}
ONLYOFFICE_DS_NODE_HOST=${ONLYOFFICE_DS_NODE_HOST:-localhost}
ONLYOFFICE_DATA_CONTAINER_PORT=80

SYSCONF_TEMPLATES_DIR="/app/onlyoffice/setup/config"

NGINX_ONLYOFFICE_PATH="${CONF_DIR}/nginx"
NGINX_ONLYOFFICE_CONF="${NGINX_ONLYOFFICE_PATH}/onlyoffice-documentserver.conf"
NGINX_ONLYOFFICE_EXAMPLE_PATH="${CONF_DIR}-example/nginx"
NGINX_ONLYOFFICE_EXAMPLE_CONF="${NGINX_ONLYOFFICE_EXAMPLE_PATH}/includes/onlyoffice-documentserver-example.conf"

NGINX_CONFIG_PATH="/etc/nginx/nginx.conf"

JWT_ENABLED=${JWT_ENABLED:-false}
JWT_SECRET=${JWT_SECRET:-secret}
JWT_HEADER=${JWT_HEADER:-Authorization}

ONLYOFFICE_DEFAULT_CONFIG=${CONF_DIR}/local.json
ONLYOFFICE_LOG4JS_CONFIG=${CONF_DIR}/log4js/production.json
ONLYOFFICE_EXAMPLE_CONFIG=${CONF_DIR}-example/local.json

JSON="json -q -f ${ONLYOFFICE_DEFAULT_CONFIG}"
JSON_LOG="json -q -f ${ONLYOFFICE_LOG4JS_CONFIG}"
JSON_EXAMPLE="json -q -f ${ONLYOFFICE_EXAMPLE_CONFIG}"

LOCAL_SERVICES=()

PG_ROOT=/var/lib/postgresql
PG_VERSION=9.5
PG_NAME=main
PGDATA=${PG_ROOT}/${PG_VERSION}/${PG_NAME}
PG_NEW_CLUSTER=false

create_local_configs(){
	for i in $ONLYOFFICE_DEFAULT_CONFIG $ONLYOFFICE_EXAMPLE_CONFIG; do
		if [ ! -f ${i} ]; then
      install -m 640 -D /dev/null ${i}
			echo {} > ${i}
		fi
  	done
}

tune_local_configs(){
	for i in $ONLYOFFICE_DEFAULT_CONFIG $ONLYOFFICE_EXAMPLE_CONFIG $ONLYOFFICE_LOG4JS_CONFIG; do
		if [ -f ${i} ]; then
			chown onlyoffice:onlyoffice -R ${i}
		fi
  	done
}


init_setting(){
  POSTGRESQL_SERVER_HOST=${POSTGRESQL_SERVER_HOST:-localhost}
  POSTGRESQL_SERVER_PORT=${POSTGRESQL_SERVER_PORT:-5432}
  POSTGRESQL_SERVER_DB_NAME=${POSTGRESQL_SERVER_DB_NAME:-onlyoffice}
  POSTGRESQL_SERVER_USER=${POSTGRESQL_SERVER_USER:-onlyoffice}
  
  RABBITMQ_SERVER_URL=${RABBITMQ_SERVER_URL:-"amqp://guest:guest@localhost"}
  parse_rabbitmq_url

  REDIS_SERVER_HOST=${REDIS_SERVER_HOST:-localhost}
  REDIS_SERVER_PORT=${REDIS_SERVER_PORT:-6379}

  DS_LOG_LEVEL=${DS_LOG_LEVEL:-all}
}

read_setting(){
  POSTGRESQL_SERVER_HOST=${POSTGRESQL_SERVER_HOST:-$(${JSON} services.CoAuthoring.sql.dbHost)}
  POSTGRESQL_SERVER_PORT=${POSTGRESQL_SERVER_PORT:-5432}
  POSTGRESQL_SERVER_DB_NAME=${POSTGRESQL_SERVER_DB_NAME:-$(${JSON} services.CoAuthoring.sql.dbName)}
  POSTGRESQL_SERVER_USER=${POSTGRESQL_SERVER_USER:-$(${JSON} services.CoAuthoring.sql.dbUser)}
  POSTGRESQL_SERVER_PASS=${POSTGRESQL_SERVER_PASS:-$(${JSON} services.CoAuthoring.sql.dbPass)}

  RABBITMQ_SERVER_URL=${RABBITMQ_SERVER_URL:-$(${JSON} rabbitmq.url)}
  parse_rabbitmq_url

  REDIS_SERVER_HOST=${REDIS_SERVER_HOST:-$(${JSON} services.CoAuthoring.redis.host)}
  REDIS_SERVER_PORT=${REDIS_SERVER_PORT:-6379}

  DS_LOG_LEVEL=${DS_LOG_LEVEL:-$(${JSON_LOG} categories.default.level)}
}

parse_rabbitmq_url(){
  local amqp=${RABBITMQ_SERVER_URL}

  # extract the protocol
  local proto="$(echo $amqp | grep :// | sed -e's,^\(.*://\).*,\1,g')"
  # remove the protocol
  local url="$(echo ${amqp/$proto/})"

  # extract the user and password (if any)
  local userpass="`echo $url | grep @ | cut -d@ -f1`"
  local pass=`echo $userpass | grep : | cut -d: -f2`

  local user
  if [ -n "$pass" ]; then
    user=`echo $userpass | grep : | cut -d: -f1`
  else
    user=$userpass
  fi

  # extract the host
  local hostport="$(echo ${url/$userpass@/} | cut -d/ -f1)"
  # by request - try to extract the port
  local port="$(echo $hostport | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"

  local host
  if [ -n "$port" ]; then
    host=`echo $hostport | grep : | cut -d: -f1`
  else
    host=$hostport
    port="5672"
  fi

  # extract the path (if any)
  local path="$(echo $url | grep / | cut -d/ -f2-)"

  RABBITMQ_SERVER_HOST=$host
  RABBITMQ_SERVER_USER=$user
  RABBITMQ_SERVER_PASS=$pass
  RABBITMQ_SERVER_PORT=$port
}

waiting_for_connection(){
  until nc -z -w 3 "$1" "$2"; do
    >&2 echo "Waiting for connection to the $3 service on $1 host on port $2"
    sleep 1
  done
}

waiting_for_postgresql(){
  waiting_for_connection ${POSTGRESQL_SERVER_HOST} ${POSTGRESQL_SERVER_PORT} "postgresql"
}

waiting_for_rabbitmq(){
  waiting_for_connection ${RABBITMQ_SERVER_HOST} ${RABBITMQ_SERVER_PORT} "rabbit"
}

waiting_for_redis(){
  waiting_for_connection ${REDIS_SERVER_HOST} ${REDIS_SERVER_PORT} "redis"
}
waiting_for_datacontainer(){
  waiting_for_connection ${ONLYOFFICE_DATA_CONTAINER_HOST} ${ONLYOFFICE_DATA_CONTAINER_PORT} "data"
}
update_postgresql_settings(){
	${JSON} -I -e "if(this.services===undefined)this.services={};"
	${JSON} -I -e "if(this.services.CoAuthoring===undefined)this.services.CoAuthoring={};"
	${JSON} -I -e "if(this.services.CoAuthoring.sql===undefined)this.services.CoAuthoring.sql={};"
  ${JSON} -I -e "this.services.CoAuthoring.sql.dbHost = '${POSTGRESQL_SERVER_HOST}'"
  ${JSON} -I -e "this.services.CoAuthoring.sql.dbPort = '${POSTGRESQL_SERVER_PORT}'"
  ${JSON} -I -e "this.services.CoAuthoring.sql.dbName = '${POSTGRESQL_SERVER_DB_NAME}'"
  ${JSON} -I -e "this.services.CoAuthoring.sql.dbUser = '${POSTGRESQL_SERVER_USER}'"
  ${JSON} -I -e "this.services.CoAuthoring.sql.dbPass = '${POSTGRESQL_SERVER_PASS}'"
}

update_rabbitmq_setting(){
  ${JSON} -I -e "if(this.rabbitmq===undefined)this.rabbitmq={};"
  ${JSON} -I -e "this.rabbitmq.url = '${RABBITMQ_SERVER_URL}'"
}

update_redis_settings(){
	${JSON} -I -e "if(this.services===undefined)this.services={};"
	${JSON} -I -e "if(this.services.CoAuthoring===undefined)this.services.CoAuthoring={};"
	${JSON} -I -e "if(this.services.CoAuthoring.redis===undefined)this.services.CoAuthoring.redis={};"
  ${JSON} -I -e "this.services.CoAuthoring.redis.host = '${REDIS_SERVER_HOST}'"
  ${JSON} -I -e "this.services.CoAuthoring.redis.port = '${REDIS_SERVER_PORT}'"
}

update_jwt_settings(){
  ${JSON} -I -e "if(this.services===undefined)this.services={};"
	${JSON} -I -e "if(this.services.CoAuthoring===undefined)this.services.CoAuthoring={};"
	${JSON} -I -e "if(this.services.CoAuthoring.token===undefined)this.services.CoAuthoring.token={};"

  if [ "${JWT_ENABLED}" == "true" -o "${JWT_ENABLED}" == "false" ]; then
  	${JSON} -I -e "if(this.services.CoAuthoring.token.enable===undefined)this.services.CoAuthoring.token.enable={};"
		${JSON} -I -e "if(this.services.CoAuthoring.token.enable.request===undefined)this.services.CoAuthoring.token.enable.request={};"
    ${JSON} -I -e "this.services.CoAuthoring.token.enable.browser = ${JWT_ENABLED}"
    ${JSON} -I -e "this.services.CoAuthoring.token.enable.request.inbox = ${JWT_ENABLED}"
    ${JSON} -I -e "this.services.CoAuthoring.token.enable.request.outbox = ${JWT_ENABLED}"
  fi

	${JSON} -I -e "if(this.services.CoAuthoring.secret===undefined)this.services.CoAuthoring.secret={};"

	${JSON} -I -e "if(this.services.CoAuthoring.secret.inbox===undefined)this.services.CoAuthoring.secret.inbox={};"
	${JSON} -I -e "this.services.CoAuthoring.secret.inbox.string = '${JWT_SECRET}'"

	${JSON} -I -e "if(this.services.CoAuthoring.secret.outbox===undefined)this.services.CoAuthoring.secret.outbox={};"
	${JSON} -I -e "this.services.CoAuthoring.secret.outbox.string = '${JWT_SECRET}'"

	${JSON} -I -e "if(this.services.CoAuthoring.secret.session===undefined)this.services.CoAuthoring.secret.session={};"
	${JSON} -I -e "this.services.CoAuthoring.secret.session.string = '${JWT_SECRET}'"

	${JSON} -I -e "if(this.services.CoAuthoring.token.inbox===undefined)this.services.CoAuthoring.token.inbox={};"
	${JSON} -I -e "this.services.CoAuthoring.token.inbox.header = '${JWT_HEADER}'"

	${JSON} -I -e "if(this.services.CoAuthoring.token.outbox===undefined)this.services.CoAuthoring.token.outbox={};"
	${JSON} -I -e "this.services.CoAuthoring.token.outbox.header = '${JWT_HEADER}'"

  if [ -f "${ONLYOFFICE_EXAMPLE_CONFIG}" ]; then
		${JSON_EXAMPLE} -I -e "if(this.server===undefined)this.server={};"
		${JSON_EXAMPLE} -I -e "if(this.server.token===undefined)this.server.token={};"

		if [ "${JWT_ENABLED}" == "true" -o "${JWT_ENABLED}" == "false" ]; then
			${JSON_EXAMPLE} -I -e "this.server.token.enable = ${JWT_ENABLED}"
		fi
		${JSON_EXAMPLE} -I -e "this.server.token.secret = '${JWT_SECRET}'"
		${JSON_EXAMPLE} -I -e "this.server.token.authorizationHeader = '${JWT_HEADER}'"
  fi
}

create_postgresql_cluster(){
  local pg_conf_dir=/etc/postgresql/${PG_VERSION}/${PG_NAME}
  local postgresql_conf=$pg_conf_dir/postgresql.conf
  local hba_conf=$pg_conf_dir/pg_hba.conf

  mv $postgresql_conf $postgresql_conf.backup
  mv $hba_conf $hba_conf.backup

  pg_createcluster ${PG_VERSION} ${PG_NAME}
}

create_postgresql_db(){
  sudo -u postgres psql -c "CREATE DATABASE onlyoffice;"
  sudo -u postgres psql -c "CREATE USER onlyoffice WITH password 'onlyoffice';"
  sudo -u postgres psql -c "GRANT ALL privileges ON DATABASE onlyoffice TO onlyoffice;"
}

create_postgresql_tbl(){
  CONNECTION_PARAMS="-h${POSTGRESQL_SERVER_HOST} -U${POSTGRESQL_SERVER_USER} -w"
  if [ -n "${POSTGRESQL_SERVER_PASS}" ]; then
    export PGPASSWORD=${POSTGRESQL_SERVER_PASS}
  fi

  PSQL="psql -q $CONNECTION_PARAMS"
  CREATEDB="createdb $CONNECTION_PARAMS"

  # Create db on remote server
  #if $PSQL -lt | cut -d\| -f 1 | grep -qw | grep 0; then
  #  $CREATEDB $POSTGRESQL_SERVER_DB_NAME
  #fi

  $PSQL -d "${POSTGRESQL_SERVER_DB_NAME}" -f "${APP_DIR}/server/schema/postgresql/createdb.sql"
}

update_nginx_settings(){

  # Set up nginx
  cp ${SYSCONF_TEMPLATES_DIR}/nginx/nginx.conf ${NGINX_CONFIG_PATH}

  sed 's/\(server \)localhost\(.*\)/'"\1${ONLYOFFICE_DS_NODE_HOST}\2"'/' \
    -i ${NGINX_ONLYOFFICE_PATH}/includes/onlyoffice-http.conf

  ln -sf ${NGINX_ONLYOFFICE_PATH}/onlyoffice-documentserver.conf.template ${NGINX_ONLYOFFICE_CONF}

  if [ -f "${NGINX_ONLYOFFICE_EXAMPLE_CONF}" ]; then
    sed 's/linux/docker/' -i ${NGINX_ONLYOFFICE_EXAMPLE_CONF}
  fi
}

update_supervisor_settings(){
  # Copy modified supervisor config
  cp ${SYSCONF_TEMPLATES_DIR}/supervisor/supervisord.conf /etc/supervisord.conf
}

update_log_settings(){
   ${JSON_LOG} -I -e "this.categories.default.level = '${DS_LOG_LEVEL}'"
}

update_logrotate_settings(){
  sed 's|\(^su\b\).*|\1 root root|' -i /etc/logrotate.conf
}

# create base folders
for i in converter docservice spellchecker metrics gc; do
  mkdir -p "${DS_LOG_DIR}/$i"
done

mkdir -p ${DS_LOG_DIR}-example

# change folder rights
for i in ${LOG_DIR} ${LIB_DIR} ${DATA_DIR}; do
  chown -R onlyoffice:onlyoffice "$i"
  chmod -R 755 "$i"
done

documentserver-generate-allfonts.sh true

if [ ${ONLYOFFICE_DATA_CONTAINER} = "true" ]; then
  create_local_configs
  init_setting

  update_log_settings
  update_jwt_settings

  update_postgresql_settings
  waiting_for_postgresql
  create_postgresql_tbl

  update_rabbitmq_setting
  update_redis_settings

  tune_local_configs

  update_nginx_settings
  nginx -g 'daemon off;'
else
  waiting_for_datacontainer
  read_setting

  waiting_for_postgresql
  waiting_for_rabbitmq
  waiting_for_redis

  update_supervisor_settings
  supervisord -n -c /etc/supervisord.conf
fi
