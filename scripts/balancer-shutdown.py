import subprocess
import sys
import os
import time
import logging
import random

grace_timer = int(os.environ.get('SHUTDOWN_TIMER')) - 60

def init_logger(name):
    logger = logging.getLogger(name)
    formatter = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logger.setLevel(logging.DEBUG)
    stdout = logging.StreamHandler()
    stdout.setFormatter(logging.Formatter(formatter))
    stdout.setLevel(logging.DEBUG)
    logger.addHandler(stdout)
    logger.info('Running a script to gracefully shutdown balancer and terminate connections\n')

def kill(name):
    logger_shutdown.info(f'Kill "{name}" process')
    command = f"pkill -15 {name}"
    try:
        subprocess.run(command, shell=True, check=True)
    except Exception as kill_msg:
        logger_shutdown.info(f'Failed to kill process "{name}": "{kill_msg}"\n')

def readFile(path, line):
    f = open(path, "r")
    data = f.read(line)
    return data

def isRunning():
    # Check that nginx.pid file is exist
    # Most of time if this file exist, master process is still runned
    pid_file = "/usr/local/openresty/nginx/logs/nginx.pid"
    if os.path.isfile(pid_file) and os.stat(pid_file).st_size != 0:
        cmd_file = "/proc/" + readFile(pid_file, 1) + "/cmdline"
        if 'nginx: master process' in readFile(cmd_file, None):
            return True
        else:
            return False
    else:
        return False

def shutdown_timer(seconds):
    logger_shutdown.info("Wait untill all connections will be closed...")
    i = 0
    rand_int = random.randint(1, 10)
    timer = int(seconds)
    while i < timer:
        i += rand_int
        if isRunning() is True:
            logger_shutdown.info("WebSocket connections exist, nginx is still running, awaiting...")
            time.sleep(5)
        elif isRunning() is False:
            break

    # Kill dumb-init process anyway if timer passed
    kill("dumb-init")
       
def ngx_shutdown():
    try:
        subprocess.run(['nginx', '-s', 'quit'], check=True)
        # Should be the same as .Values.customBalancer.terminationGracePeriodSeconds like:
        shutdown_timer(grace_timer)
    except Exception as quit_msg:
        logger_shutdown.error(f'Failed nginx soft stop attempt: "{quit_msg}"\n')
        # Kill dumb-init if nginx -s quit return some errors
        kill("dumb-init")

init_logger('shutdown')
logger_shutdown = logging.getLogger('shutdown.balancer')
ngx_shutdown()
