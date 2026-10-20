import subprocess
import logging
import sched
import time
import re
import os
from kubernetes import client, config


def init_logger(name):
    logger = logging.getLogger(name)
    formatter = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logger.setLevel(logging.DEBUG)
    stdout = logging.StreamHandler()
    stdout.setFormatter(logging.Formatter(formatter))
    stdout.setLevel(logging.DEBUG)
    logger.addHandler(stdout)
    logger.info('Running the entrypoint of the DocumentServer balancer\n')


def set_nginx_parameter():
    logger_entrypoint_balancer.info('Running the setting of values in Nginx config')
    nginx_worker_processes = os.environ.get('BALANCER_WORKER_PROCESSES')
    nginx_worker_connections = os.environ.get('BALANCER_WORKER_CONNECTIONS')
    nginx_worker_timeout = os.environ.get('BALANCER_WORKER_TIMEOUT')
    path = '/usr/local/openresty/nginx/conf/nginx.conf'
    try:
        with open(path, "r") as nginx_conf_read:
            nginx_config = nginx_conf_read.read()
        worker_processes = re.sub(r"worker_processes.*", f'worker_processes {nginx_worker_processes};', nginx_config)
        worker_connections = re.sub(r"worker_connections.*", f'worker_connections {nginx_worker_connections};', worker_processes)
        worker_shutdown = re.sub(r"worker_shutdown_timeout.*", f'worker_shutdown_timeout {nginx_worker_timeout};', worker_connections)
        with open(path, "w") as config_write:
            config_write.write(worker_shutdown)
    except Exception as msg_set_nginx_conf:
        logger_entrypoint_balancer.error(f'Failed when trying to set a value in the Nginx config... {msg_set_nginx_conf}\n')
    else:
        logger_entrypoint_balancer.info('Setting values in Nginx config is completed\n')


def running_services():
    ep_name = os.environ["DS_EP_NAME"]
    label_name = f"kubernetes.io/service-name={ep_name}"
    pathNS = '/run/secrets/kubernetes.io/serviceaccount/namespace'
    with open(pathNS, "r") as f_ns:
        ns = f_ns.read().strip()
    config.load_incluster_config()
    disc = client.DiscoveryV1Api()
    try:
        running_nginx = ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
        running_cm_observer = ["python3", "/scripts/balancer-cm-observer.py"]
        running_get_ds_ep = ["python3", "/scripts/ds-ep-observer.py"]
        running_get_ds_pod = ["python3", "/scripts/ds-pod-observer.py"]
        all_cmd = [
            ('openresty', running_nginx),
            ('balancer-cm-observer.py', running_cm_observer),
            ('ds-ep-observer.py', running_get_ds_ep)
        ]
        try:
            disc.list_namespaced_endpoint_slice(namespace=ns, label_selector=label_name, _preload_content=False)
        except Exception as msg_get_ep_slices:
            logger_entrypoint_balancer.warning(f'EndpointSlice API probe failed: {msg_get_ep_slices}')
            all_cmd.append(('ds-pod-observer.py', running_get_ds_pod))
        else:
            logger_entrypoint_balancer.info('EndpointSlice API probe successfully')
        for name, cmd in all_cmd:
            cmd_process = subprocess.Popen(cmd)
            logger_entrypoint_balancer.info(f'The "{name}" process has been running with PID {cmd_process.pid}')
    except Exception as msg_running_services:
        logger_entrypoint_balancer.error(f'Failed when trying to run the service... {msg_running_services}\n')


def loop(forever_scheduler):
    forever_scheduler.enter(300, 1, loop, (forever_scheduler,))
    pass


init_logger('balancer')
logger_entrypoint_balancer = logging.getLogger('balancer.ds')
set_nginx_parameter()
running_services()
scheduler = sched.scheduler(time.time, time.sleep)
scheduler.enter(300, 1, loop, (scheduler,))
scheduler.run()
