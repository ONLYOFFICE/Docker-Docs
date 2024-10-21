import os
import logging
import requests
import json
import time
from kubernetes import client, watch

ep_name = os.environ["DS_EP_NAME"]
field_name = f'metadata.name={ep_name}'

url_sending = f'http://127.0.0.1:8000/configuration'

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
    logger.info('Running the script to get the endpoints of the DocumentServer\n')


def read_pod_annotation(pod_name):
    try:
        annotation = v1.read_namespaced_pod(pod_name, ns)
        version = annotation.metadata.annotations["ds-ver-hash"]
        return version
    except Exception as msg_read_pod:
        logger_endpoints_ds.error(f'Error when reading an annotation to the Pod... {msg_read_pod}')
        return 'none'


def get_ep_list(ep_ds, ep_port):
    ds_ep_list = []
    total_result = {}
    for ep_ip in ep_ds:
        try:
            pod_name = ep_ip.target_ref.name
            ver_ds = read_pod_annotation(pod_name)
            total_result['address'] = ep_ip.ip
            total_result['port'] = ep_port
            total_result['ver'] = ver_ds
            ds_ep_list.append(json.dumps(total_result))
        except Exception as msg_url:
            logger_endpoints_ds.error(f'Failed to build a list of endpoints: {ds_ep_list}... {msg_url}')
    all_ep = f'{ds_ep_list}'.replace("'", "")
    requests.post(url_sending, data=all_ep)


def get_ds_status():
    while True:
        try:
            w = watch.Watch()
            for event in w.stream(v1.list_namespaced_endpoints, namespace=ns, field_selector=field_name):
                try:
                    if event['object'].subsets:
                        ep_ds = event['object'].subsets[0].addresses
                        ep_port = str(event['object'].subsets[0].ports[0].port)
                        if not ep_ds:
                            logger_endpoints_ds.warning(f'Empty "{ep_name}" endpoints list')
                            requests.post(url_sending, data="none")
                        else:
                            get_ep_list(ep_ds, ep_port)
                    else:
                        logger_endpoints_ds.warning(f'There are no addresses for endpoint "{ep_name}"')
                        requests.post(url_sending, data="none")
                except Exception as msg_list_ep:
                    logger_endpoints_ds.error(f'Error when trying to list "{ep_name}" endpoints... {msg_list_ep}')
                    requests.post(url_sending, data="none")
        except Exception as msg_get_ep:
            logger_endpoints_ds.warning(f'Trying to search "{ep_name}" endpoints... {msg_get_ep}')
            time.sleep(1)


init_logger('endpoints')
logger_endpoints_ds = logging.getLogger('endpoints.ds')
get_ds_status()
