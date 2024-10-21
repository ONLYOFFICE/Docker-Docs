import subprocess
import logging
import sched
import time
import re
import os


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
    logger_endpoints_ds.info('Running the setting of values in Nginx config')
    nginx_worker_processes = os.environ.get('BALANCER_WORKER_PROCESSES')
    nginx_worker_connections = os.environ.get('BALANCER_WORKER_CONNECTIONS')
    path = '/usr/local/openresty/nginx/conf/nginx.conf'
    try:
        with open(path, "r") as nginx_conf_read:
            nginx_config = nginx_conf_read.read()
        worker_processes = re.sub(r"worker_processes.*", f'worker_processes {nginx_worker_processes};', nginx_config)
        worker_connections = re.sub(r"worker_connections.*", f'worker_connections {nginx_worker_connections};', worker_processes)
        with open(path, "w") as config_write:
            config_write.write(worker_connections)
    except Exception as msg_set_nginx_conf:
        logger_endpoints_ds.error(f'Failed when trying to set a value in the Nginx config... {msg_set_nginx_conf}\n')
    else:
        logger_endpoints_ds.info('Setting values in Nginx config is completed\n')


def running_services():
    try:
        running_nginx = ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]
        running_get_ds_ep = ["python3", "/ds_ep_observer/ds-ep-observer.py"]
        running_get_ds_pod = ["python3", "/ds_ep_observer/ds-pod-observer.py"]
        all_cmd = [running_nginx, running_get_ds_ep, running_get_ds_pod]
        for cmd in all_cmd:
            cmd_process = subprocess.Popen(cmd)
            logger_endpoints_ds.info(f'The "{cmd_process.pid}" process has been running')
    except Exception as msg_running_services:
        logger_endpoints_ds.error(f'Failed when trying to run the service... {msg_running_services}\n')


def loop(forever_scheduler):
    forever_scheduler.enter(300, 1, loop, (forever_scheduler,))
    pass


init_logger('balancer')
logger_endpoints_ds = logging.getLogger('balancer.ds')
set_nginx_parameter()
running_services()
scheduler = sched.scheduler(time.time, time.sleep)
scheduler.enter(300, 1, loop, (scheduler,))
scheduler.run()
