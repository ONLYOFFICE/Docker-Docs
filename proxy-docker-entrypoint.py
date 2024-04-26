import os, re, shutil
 
if not os.path.isdir("/tmp/proxy_nginx"):
    shutil.copytree("/etc/nginx", "/tmp/proxy_nginx")

nginxConfPath = "/tmp/proxy_nginx/nginx.conf"
dsConfPath = "/tmp/proxy_nginx/conf.d/ds.conf"
dsCommonPath = "/tmp/proxy_nginx/includes/ds-common.conf"
dsDocservicePath = "/tmp/proxy_nginx/includes/ds-docservice.conf"

def envsubst(inPath, outPath):
  with open(inPath, 'r') as file:
    conf = file.read()
    for i in re.findall(r'\$[a-zA-Z_]*', conf):
        for j in os.environ:
            if i[1:] == j:
                conf = conf.replace(i, os.environ[j])
  with open(outPath, 'w') as file:
    file.write(conf)

envsubst("/tmp/proxy_nginx/includes/http-upstream.conf", "/tmp/http-upstream.conf")
envsubst("/etc/nginx/includes/ds-common.conf", dsCommonPath)

with open(nginxConfPath, 'r') as file:
    nginx = file.read()
nginx = re.sub(r"worker_connections\s[0-9]+", "worker_connections {0}".format(os.environ.get("NGINX_WORKER_CONNECTIONS")), nginx)
if os.environ.get("NGINX_ACCESS_LOG") != "off" :
    nginx = re.sub(r"access_log.*", "access_log {0}".format(os.environ.get("NGINX_ACCESS_LOG")), nginx)
with open(nginxConfPath, 'w') as file:
    file.write(nginx)

with open(dsConfPath, 'r') as file:
    ds = file.read()
ds = re.sub(r"set\s\$secure_link_secret.*", "set $secure_link_secret {0};".format(os.environ.get("SECURE_LINK_SECRET", "verysecretstring")), ds)
if not os.path.isfile("/proc/net/if_inet6"):
    ds = re.sub(r"listen\s\[::]:[0-9]+.*", "", ds)
with open(dsConfPath, 'w') as file:
    file.write(ds)

with open(dsCommonPath, 'r') as file:
    common = file.read()
common = re.sub(r"client_max_body_size.*", "client_max_body_size {0};".format(os.environ.get("NGINX_CLIENT_MAX_BODY_SIZE")), common)
with open(dsCommonPath, 'w') as file:
    file.write(common)

with open(dsDocservicePath, 'r') as file:
    docService = file.read()
    if os.environ.get("INFO_ALLOWED_IP"):
        ip = os.environ.get("INFO_ALLOWED_IP").split()
        ipStr = ""
        for i in ip:
            ipStr = ipStr + "  allow {0};\n".format(i)
        docService = re.sub(r"(location.*\(info\).*)", r"\1\n" + ipStr[:-1], docService)       
    if os.environ.get("INFO_ALLOWED_USER"):
        os.system('htpasswd -c -b /tmp/auth "${INFO_ALLOWED_USER}" "${INFO_ALLOWED_PASSWORD:-password}"')
        docService = re.sub(r"(location.*\(info\).*)", "\1\n  auth_basic \"Authentication Required;\"\n  auth_basic_user_file /tmp/auth;", docService)
with open(dsDocservicePath, 'w') as file:
    file.write(docService)
os.system('exec nginx -c /tmp/proxy_nginx/nginx.conf -g \'daemon off;\'')
