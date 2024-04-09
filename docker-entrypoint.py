import os, json, sys
LOG_LEVEL = os.environ.get("LOG_LEVEL")
LOG_TYPE = os.environ.get("LOG_TYPE")
LOG_PATTERN = os.environ.get("LOG_PATTERN")
COMPANY_NAME = os.environ.get("COMPANY_NAME", "onlyoffice")
METRICS_ENABLED = os.environ.get("METRICS_ENABLED", "false") 
METRICS_HOST = os.environ.get("METRICS_HOST", "localhost") 
METRICS_PORT = os.environ.get("METRICS_PORT", "8125")
METRICS_PREFIX = os.environ.get("METRICS_PREFIX", "ds.")
DB_TYPE = os.environ.get("DB_TYPE", "postgres")
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432") 
DB_USER = os.environ.get("DB_USER", "onlyoffice")
DB_NAME = os.environ.get("DB_NAME", DB_USER) 
DB_PWD =  os.environ.get("DB_PWD", "")
REDIS_CONNECTOR_NAME = os.environ.get("REDIS_CONNECTOR_NAME", "redis") 
REDIS_SERVER_HOST = os.environ.get("REDIS_SERVER_HOST", "localhost")
REDIS_SERVER_PORT = os.environ.get("REDIS_SERVER_PORT", "6379")
REDIS_SERVER_USER = os.environ.get("REDIS_SERVER_USER", "default")
REDIS_SERVER_PWD = os.environ.get("REDIS_SERVER_PWD", "")
REDIS_SERVER_DB_NUM = os.environ.get("REDIS_SERVER_DB_NUM", "0") 
REDIS_CLUSTER = os.environ.get("REDIS_CLUSTER")
REDIS_CLUSTER_NODES = os.environ.get("REDIS_CLUSTER_NODES")
REDIS_SENTINEL_GROUP_NAME = os.environ.get("REDIS_SENTINEL_GROUP_NAME", "mymaster")
JWT_ENABLED = os.environ.get("JWT_ENABLED", "true")
JWT_ENABLED_INBOX = os.environ.get("JWT_ENABLED_INBOX", JWT_ENABLED)
JWT_ENABLED_OUTBOX = os.environ.get("JWT_ENABLED_OUTBOX", JWT_ENABLED)
JWT_HEADER = os.environ.get("JWT_HEADER", "Authorization")
JWT_HEADER_INBOX = os.environ.get("JWT_HEADER_INBOX", JWT_HEADER)
JWT_HEADER_OUTBOX = os.environ.get("JWT_HEADER_OUTBOX", JWT_HEADER)
JWT_IN_BODY = os.environ.get("JWT_IN_BODY", "false")
JWT_SECRET = os.environ.get("JWT_SECRET", "secret")
JWT_SECRET_INBOX = os.environ.get("JWT_SECRET_INBOX", "secret")
JWT_SECRET_OUTBOX = os.environ.get("JWT_SECRET_OUTBOX", "secret")
ALLOW_PRIVATE_IP_ADDRESS = os.environ.get("ALLOW_PRIVATE_IP_ADDRESS", "false")
ALLOW_META_IP_ADDRESS = os.environ.get("ALLOW_META_IP_ADDRESS", "false")
ALLOW_IP_ADDRESS_LIST = os.environ.get("ALLOW_IP_ADDRESS_LIST", "[]")
DENY_IP_ADDRESS_LIST = os.environ.get("DENY_IP_ADDRESS_LIST", "[]")
AMQP_TYPE = os.environ.get("AMQP_TYPE", "rabbitmq")
AMQP_PORT = os.environ.get("AMQP_PORT", "5672")
AMQP_HOST = os.environ.get("AMQP_HOST", "localhost")
AMQP_USER = os.environ.get("AMQP_USER", "guest")
AMQP_PWD =  os.environ.get("AMQP_PWD", "guest")
ACTIVEMQ_TRANSPORT = os.environ.get("ACTIVEMQ_TRANSPORT")
AMQP_PROTO = os.environ.get("AMQP_PROTO", "amqp")
AMQP_VHOST = os.environ.get("AMQP_VHOST", "/")
AMQP_URI =  os.environ.get("AMQP_URI", AMQP_PROTO + "://" + AMQP_USER + ":" + AMQP_PWD + "@" + AMQP_HOST + ":" + AMQP_PORT + AMQP_VHOST)
WOPI_ENABLED = os.environ.get("WOPI_ENABLED", "false")
SECURE_LINK_SECRET = os.environ.get("SECURE_LINK_SECRET", "verysecretstring")

if LOG_LEVEL or LOG_TYPE or LOG_PATTERN:
    #filePath = "/etc/" + COMPANY_NAME + "/documentserver/log4js/production.json"
    filePath = "c:\\Users\\pc\\Documents\\ttt.json"
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

if AMQP_PROTO == "amqps" or AMQP_PROTO == "amqp+ssl":
    ACTIVEMQ_TRANSPORT = "tls"
else:
    ACTIVEMQ_TRANSPORT = "tcp"

if REDIS_CLUSTER_NODES:
    lst = REDIS_CLUSTER_NODES.split()
    nodes = []
    for i in lst:
        nodes.append({ "url": "redis://" + i })
    nodesDict = {"rootNodes": nodes, "defaults": { "username": REDIS_SERVER_USER, "password": REDIS_SERVER_PWD }}
    nodesString = json.dumps(nodesDict)
    nodesString = nodesString[1:-1]
    os.environ['REDIS_CLUSTER'] = nodesString
else:
    os.environ['REDIS_CLUSTER'] = ''

nodeDict = {
  "statsd": {
    "useMetrics": METRICS_ENABLED,
	  "host": METRICS_HOST,
	  "port": METRICS_PORT,
	  "prefix": METRICS_PREFIX
	},
  "services": {
    "CoAuthoring": {
      "sql": {
        "type": DB_TYPE,
        "dbHost": DB_HOST,
        "dbPort": DB_PORT,
        "dbUser": DB_USER,
        "dbName": DB_NAME,
        "dbPass": DB_PWD
      },
      "redis": {
        "name": REDIS_CONNECTOR_NAME,
        "host": REDIS_SERVER_HOST,
        "port": REDIS_SERVER_PORT,
        "options": {
          "user": REDIS_SERVER_USER,
          "password": REDIS_SERVER_PWD,
          "db": REDIS_SERVER_DB_NUM
        },
        "optionsCluster": REDIS_CLUSTER,
        "iooptions": {
          "sentinels": [
            {
              "host": REDIS_SERVER_HOST,
              "port": REDIS_SERVER_PORT
            }
          ],
          "name": REDIS_SENTINEL_GROUP_NAME,
          "username": REDIS_SERVER_USER,
          "password": REDIS_SERVER_PWD,
          "db": REDIS_SERVER_DB_NUM
        }
      },
      "token": {
        "enable": {
          "browser": JWT_ENABLED,
          "request": {
            "inbox": JWT_ENABLED_INBOX,
            "outbox": JWT_ENABLED_OUTBOX
          }
        },
        "inbox": {
          "header": JWT_HEADER_INBOX,
          "inBody": JWT_IN_BODY
        },
        "outbox": {
          "header": JWT_HEADER_OUTBOX,
          "inBody": JWT_IN_BODY
        }
      },
      "secret": {
        "inbox": {
          "string": JWT_SECRET_INBOX
        },
        "outbox": {
          "string": JWT_SECRET_OUTBOX
        },
        "session": {
          "string": JWT_SECRET
        }        
      },
      "request-filtering-agent" : {
        "allowPrivateIPAddress": ALLOW_PRIVATE_IP_ADDRESS,
        "allowMetaIPAddress": ALLOW_META_IP_ADDRESS,
        "allowIPAddressList": ALLOW_IP_ADDRESS_LIST,
        "denyIPAddressList": DENY_IP_ADDRESS_LIST
      }
    }
  },
  "queue": {
    "type": AMQP_TYPE
  },
  "activemq": {
    "connectOptions": {
      "port": AMQP_PORT,
      "host": AMQP_HOST,
      "username": AMQP_USER,
      "password": AMQP_PWD,
      "transport": ACTIVEMQ_TRANSPORT
    }
  },
  "rabbitmq": {
    "url": AMQP_URI
  },
  "wopi": {
    "enable": WOPI_ENABLED
  },
  "FileConverter": {
    "converter": {
        "maxprocesscount": 0.001
    }  
  },
  "storage": {
    "fs": {
      "secretString": SECURE_LINK_SECRET
    }
  }
}

NODE_CONFIG = json.dumps(nodeDict, indent=4)
os.environ['NODE_CONFIG'] = NODE_CONFIG
os.system(sys.argv[1])

