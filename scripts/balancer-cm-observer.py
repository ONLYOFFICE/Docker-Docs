from kubernetes import client, config, watch
import os
import logging
import requests
import json
import time
import subprocess
import hashlib

cm_name = os.environ["BALANCER_CM_NAME"]
cm_key = "balancer-lua.conf"
cm_path = "/etc/nginx/mnt_config/balancer-lua.conf"
cm_sha = None
log_level = os.environ.get('LOG_LEVEL')

pathNS = '/run/secrets/kubernetes.io/serviceaccount/namespace'
with open(pathNS, "r") as f_ns:
    ns = f_ns.read().strip()


def _get_v1():
    config.load_incluster_config()
    return client.CoreV1Api()


def init_logger(name):
    logger = logging.getLogger(name)
    formatter = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logger.setLevel(logging.DEBUG)
    stdout = logging.StreamHandler()
    stdout.setFormatter(logging.Formatter(formatter))
    stdout.setLevel(logging.DEBUG)
    logger.addHandler(stdout)
    logger.info('Running Docs-Balancer configMap observer service...')


def calculate_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

# Watch for changes in the ConfigMap
def watch_configmap_changes():
    global cm_sha
    field_selector = f"metadata.name={cm_name}"
    while True:
        if log_level == 'DEBUG':
            logger_cm_observer.debug(f'The Watch cycle for the "{cm_name}" ConfigMap is running')
        try:
            v1 = _get_v1()
            w = watch.Watch()
            for event in w.stream(v1.list_namespaced_config_map, namespace=ns, field_selector=field_selector):
                try:
                    f = open(cm_path, "w")
                    f.write(event['object'].data[cm_key])
                    f.close()
                    new_sha256 = calculate_sha256(cm_path)
                    if log_level == 'DEBUG':
                        logger_cm_observer.debug(f'ConfigMap "{cm_name}" received and sent')
                    if not cm_sha or cm_sha != new_sha256:
                        cm_sha = new_sha256
                        reload_nginx()
                except Exception as msg_write_cm:
                    logger_cm_observer.error(f'Cant write in config file...{msg_write_cm}')
        except Exception as msg_get_cm:
            logger_cm_observer.warning(f'Trying to get cm data...{msg_get_cm}')
            time.sleep(1)
        if log_level == 'DEBUG':
            logger_cm_observer.debug(f'The Watch cycle for the "{cm_name}" ConfigMap is ending')


def reload_nginx():
    try:
        subprocess.run(['nginx', '-s', 'reload'], check=True)
    except Exception as quit_msg:
        logger_cm_observer.error(f'Failed nginx reload attempt: "{quit_msg}"\n')

# Init logger
init_logger('configmap')
logger_cm_observer = logging.getLogger('configmap.balancer')

# Start watching for changes
watch_configmap_changes()
