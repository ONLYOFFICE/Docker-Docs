import os
import logging
import requests
import json
import time
from kubernetes import client, watch

label = os.environ["DS_POD_LABEL"]
ep_port = os.environ["SHARD_PORT"]
log_level = os.environ.get('LOG_LEVEL')

url_sending = f'http://127.0.0.1:8000/configuration_reserved'

k8s_host = os.environ["KUBERNETES_SERVICE_HOST"]
api_server = f'https://{k8s_host}'
pathCrt = '/run/secrets/kubernetes.io/serviceaccount/ca.crt'
pathToken = '/run/secrets/kubernetes.io/serviceaccount/token'
pathNS = '/run/secrets/kubernetes.io/serviceaccount/namespace'

with open(pathToken, "r") as f_tok:
    token = f_tok.read()

with open(pathNS, "r") as f_ns:
    ns = f_ns.read()

configuration = client.Configuration()
configuration.ssl_ca_cert = pathCrt
configuration.host = api_server
configuration.verify_ssl = True
configuration.debug = False
configuration.api_key = {"authorization": "Bearer " + token}
client.Configuration.set_default(configuration)
v1 = client.CoreV1Api()


def init_logger(name):
    logger = logging.getLogger(name)
    formatter = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logger.setLevel(logging.DEBUG)
    stdout = logging.StreamHandler()
    stdout.setFormatter(logging.Formatter(formatter))
    stdout.setLevel(logging.DEBUG)
    logger.addHandler(stdout)
    logger.info('Running the script to get the Pods of the DocumentServer\n')


def get_running_pod():
    ds_ep_list = []
    total_result = {}
    pods_list = v1.list_namespaced_pod(namespace=ns, label_selector=label)
    if pods_list.items:
        for pod in pods_list.items:
            try:
                if pod.status.container_statuses[("name" == "proxy")].ready == True:
                    total_result['address'] = pod.status.pod_ip
                    total_result['port'] = ep_port
                    total_result['ver'] = pod.metadata.annotations["ds-ver-hash"]
                    ds_ep_list.append(json.dumps(total_result))
            except Exception as msg_url:
                logger_pod_ds.error(f'Failed to build a list of Running {pod.metadata.name} Pod: {ds_ep_list}... {msg_url}')
        if not ds_ep_list:
            requests.post(url_sending, data="none")
        else:
            all_ep = f'{ds_ep_list}'.replace("'", "")
            requests.post(url_sending, data=all_ep)
    else:
        requests.post(url_sending, data="none")


def get_ds_pod():
    while True:
        if log_level == 'DEBUG':
            logger_pod_ds.debug(f'The Watch cycle for the "{label}" Pods is running')
        try:
            w = watch.Watch()
            for event in w.stream(v1.list_namespaced_pod, namespace=ns, label_selector=label):
                try:
                    if event['object'].metadata.deletion_timestamp:
                        if log_level == 'DEBUG':
                            logger_pod_ds.debug(f'Pods "{label}" received and sent')
                        get_running_pod()
                except Exception as msg_list_pod:
                    logger_pod_ds.error(f'Error when trying to list "{label}" Pods... {msg_list_pod}')
                    requests.post(url_sending, data="none")
        except Exception as msg_get_pod:
            logger_pod_ds.warning(f'Trying to search "{label}" Pods... {msg_get_pod}')
            time.sleep(1)
        if log_level == 'DEBUG':
            logger_pod_ds.debug(f'The Watch cycle for the "{label}" Pods is ending')


init_logger('pods')
logger_pod_ds = logging.getLogger('pods.ds')
get_ds_pod()
