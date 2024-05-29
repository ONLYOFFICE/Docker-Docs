import os, json, sys
LOG_LEVEL = os.environ.get("LOG_LEVEL")
LOG_TYPE = os.environ.get("LOG_TYPE")
LOG_PATTERN = os.environ.get("LOG_PATTERN")
COMPANY_NAME = os.environ.get("COMPANY_NAME", "onlyoffice")
REDIS_SERVER_USER = os.environ.get("REDIS_SERVER_USER", "default")
REDIS_SERVER_PWD = os.environ.get("REDIS_SERVER_PWD", "")
REDIS_CLUSTER = os.environ.get("REDIS_CLUSTER")
REDIS_CLUSTER_NODES = os.environ.get("REDIS_CLUSTER_NODES")
REDIS_SENTINEL_GROUP_NAME = os.environ.get("REDIS_SENTINEL_GROUP_NAME", "mymaster")
REDIS_CONNECTOR_NAME = os.environ.get("REDIS_CONNECTOR_NAME", "redis")
AMQP_TYPE = os.environ.get("AMQP_TYPE", "rabbitmq")
AMQP_PORT = os.environ.get("AMQP_PORT", "5672")
AMQP_HOST = os.environ.get("AMQP_HOST", "localhost")
AMQP_USER = os.environ.get("AMQP_USER", "guest")
AMQP_PWD =  os.environ.get("AMQP_PWD", "guest")
ACTIVEMQ_TRANSPORT = os.environ.get("ACTIVEMQ_TRANSPORT")
AMQP_PROTO = os.environ.get("AMQP_PROTO", "amqp")
AMQP_VHOST = os.environ.get("AMQP_VHOST", "/")
AMQP_URI =  os.environ.get("AMQP_URI", AMQP_PROTO + "://" + AMQP_USER + ":" + AMQP_PWD + "@" + AMQP_HOST + ":" + AMQP_PORT + AMQP_VHOST)

if LOG_LEVEL or LOG_TYPE or LOG_PATTERN:
    filePath = "/etc/{0}/documentserver/log4js/production.json".format(COMPANY_NAME)
    with open(filePath, 'r') as json_file:
        logConfig = json.load(json_file)
    if LOG_LEVEL:
        logConfig["categories"]["default"]["level"] = LOG_LEVEL
    if LOG_TYPE:
        logConfig["appenders"]["default"]["layout"]["type"] = LOG_TYPE
    if LOG_PATTERN:
        logConfig["appenders"]["default"]["layout"]["pattern"] = LOG_PATTERN
    with open(filePath, "w") as json_file:
        json.dump(logConfig, json_file, indent=4)

if REDIS_CLUSTER_NODES:
    lst = REDIS_CLUSTER_NODES.split()
    nodes = []
    for i in lst:
        nodes.append({ "url": "redis://" + i })
    redisConfig = {"optionsCluster": {"rootNodes": nodes, "defaults": { "username": REDIS_SERVER_USER, "password": REDIS_SERVER_PWD }}}
elif REDIS_CONNECTOR_NAME == "ioredis":
    redisConfig = {
        "iooptions": {
          "sentinels": [
            {
              "host": os.environ.get("REDIS_SERVER_HOST", "localhost"),
              "port": os.environ.get("REDIS_SERVER_PORT", "6379")
            }
          ],
          "name": REDIS_SENTINEL_GROUP_NAME,
          "username": REDIS_SERVER_USER,
          "password": REDIS_SERVER_PWD,
          "db": os.environ.get("REDIS_SERVER_DB_NUM", "0")
        }
    }
else:
    redisConfig = {
        "name": os.environ.get("REDIS_CONNECTOR_NAME", "redis"),
        "host": os.environ.get("REDIS_SERVER_HOST", "localhost"),
        "port": os.environ.get("REDIS_SERVER_PORT", "6379"),
        "options": {
          "user": REDIS_SERVER_USER,
          "password": REDIS_SERVER_PWD,
          "db": os.environ.get("REDIS_SERVER_DB_NUM", "0")
        }
    }

nodeDict = {
  "statsd": {
    "useMetrics": os.environ.get("METRICS_ENABLED", "false"),
	  "host": os.environ.get("METRICS_HOST", "localhost"),
	  "port": os.environ.get("METRICS_PORT", "8125"),
	  "prefix": os.environ.get("METRICS_PREFIX", "ds.")
	},
  "services": {
    "CoAuthoring": {
      "sql": {
        "type": os.environ.get("DB_TYPE", "postgres"),
        "dbHost": os.environ.get("DB_HOST", "localhost"),
        "dbPort": os.environ.get("DB_PORT", "5432"),
        "dbUser": os.environ.get("DB_USER", "onlyoffice"),
        "dbName": os.environ.get("DB_NAME", os.environ.get("DB_USER", "onlyoffice")),
        "dbPass": os.environ.get("DB_PWD", "onlyoffice")
      },
      "redis": redisConfig,       
      "token": {
        "enable": {
          "browser": os.environ.get("JWT_ENABLED", "true"),
          "request": {
            "inbox": os.environ.get("JWT_ENABLED_INBOX", os.environ.get("JWT_ENABLED", "true")),
            "outbox": os.environ.get("JWT_ENABLED_OUTBOX", os.environ.get("JWT_ENABLED", "true"))
          }
        },
        "inbox": {
          "header": os.environ.get("JWT_HEADER_INBOX", os.environ.get("JWT_HEADER", "Authorization")),
          "inBody": os.environ.get("JWT_IN_BODY", "false")
        },
        "outbox": {
          "header": os.environ.get("JWT_HEADER_OUTBOX", os.environ.get("JWT_HEADER", "Authorization")),
          "inBody": os.environ.get("JWT_IN_BODY", "false")
        }
      },
      "secret": {
        "inbox": {
          "string": os.environ.get("JWT_SECRET_INBOX", "secret")
        },
        "outbox": {
          "string": os.environ.get("JWT_SECRET_OUTBOX", "secret")
        },
        "session": {
          "string": os.environ.get("JWT_SECRET", "secret")
        }        
      },
      "request-filtering-agent" : {
        "allowPrivateIPAddress": os.environ.get("ALLOW_PRIVATE_IP_ADDRESS", "false"),
        "allowMetaIPAddress": os.environ.get("ALLOW_META_IP_ADDRESS", "false"),
        "allowIPAddressList": os.environ.get("ALLOW_IP_ADDRESS_LIST", "[]"),
        "denyIPAddressList": os.environ.get("DENY_IP_ADDRESS_LIST", "[]")
      }
    }
  },
  "queue": {
    "type": AMQP_TYPE
  },
  "wopi": {
    "enable": os.environ.get("WOPI_ENABLED", "false")
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }
  },
  "storage": {
    "fs": {
      "folderPath": "/var/lib/{0}/documentserver/App_Data/cache/files/".format(COMPANY_NAME) + os.environ.get("STORAGE_SUBDIRECTORY_NAME", "latest"),
      "secretString": os.environ.get("SECURE_LINK_SECRET", "verysecretstring")
    },
    "storageFolderName": "files/" + os.environ.get("STORAGE_SUBDIRECTORY_NAME", "latest")
  },
  "persistentStorage": {
    "fs": {
      "folderPath": "/var/lib/{0}/documentserver/App_Data/cache/files".format(COMPANY_NAME),
      "secretString": os.environ.get("SECURE_LINK_SECRET", "verysecretstring")
    },
    "storageFolderName": "files"
  }
}

if AMQP_TYPE == "rabbitmq":
    amqpConfig = {
      "url": AMQP_URI
    }
    nodeDict['rabbitmq'] = amqpConfig
elif AMQP_TYPE == "activemq":
    if AMQP_PROTO == "amqps" or AMQP_PROTO == "amqp+ssl":
        ACTIVEMQ_TRANSPORT = "tls"
    else:
        ACTIVEMQ_TRANSPORT = "tcp"
    amqpConfig = {
      "connectOptions": {
        "port": AMQP_PORT,
        "host": AMQP_HOST,
        "username": AMQP_USER,
        "password": AMQP_PWD,
        "transport": ACTIVEMQ_TRANSPORT
        }
    }
    nodeDict['activemq'] = amqpConfig

NODE_CONFIG = json.dumps(nodeDict, indent=4)
os.environ['NODE_CONFIG'] = NODE_CONFIG
os.system(sys.argv[1])

