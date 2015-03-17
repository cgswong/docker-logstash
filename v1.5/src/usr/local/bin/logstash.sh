#!/bin/bash
# #################################################################
# NAME: logstash.sh
# DESC: Logstash startup file.
#
# LOG:
# yyyy/mm/dd [user] [version]: [notes]
# 2015/02/02 cgwong v0.1.0: Use confd for configuration management.
# #################################################################

# Fail hard and fast
set -eo pipefail

# Set environment variables
LS_HOME="/opt/logstash"
LS_CFG_FILE=${LS_CFG_FILE:-"/etc/logstash/conf.d/logstash.conf"}

LSF_CERT_FILE=${LSF_CERT_FILE:-"/etc/logstash/ssl/logstash-forwarder.cert"}
LSF_KEY_FILE=${LSF_KEY_FILE:-"/etc/logstash/ssl/logstash-forwarder.key"}

ES_CLUSTER=${ES_CLUSTER:-"es01"}
ES_HOST=${ES_HOST:-"localhost"}
ES_PORT=${ES_PORT:-"9200"}

REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-"6379"}

STATUS=0

# Download the config file, if given a URL
if [ ! -z "$LS_CFG_URL" ]; then
  echo "[logstash] Downloading logstash conf file from ${LS_CFG_URL}"
  curl -Ls -o ${LS_CFG_FILE} ${LS_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[logstash] Failed to download ${LS_CFG_URL} exiting."
    exit 1
  fi
fi
# Update logstash.conf file with needed info
sed -ie "s/ES_CLUSTER/${ES_CLUSTER}/" $LS_CFG_FILE
sed -ie "s/ES_HOST/${ES_HOST}/" $LS_CFG_FILE
sed -ie "s/ES_PORT/${ES_PORT}/" $LS_CFG_FILE
sed -ie "s/REDIS_HOST/${REDIS_HOST}/" $LS_CFG_FILE
sed -ie "s/REDIS_PORT/${REDIS_PORT}/" $LS_CFG_FILE

# Download SSL cert if given a URL
if [ ! "$LSF_CERT_URL" ]; then
  echo "[logstash] Downloading logstash-forwarder cert from ${LSF_CERT_URL}"
  curl -Ls -o ${LSF_CERT_FILE} ${LSF_CERT_URL}
  if [ $? -ne 0 ]; then
    echo "[logstash] Failed to download ${LSF_CERT_URL} exiting."
    exit 1
  fi
fi
# Download SSL key if given a URL
if [ ! -z "$LSF_KEY_URL" ]; then
  echo "[logstash] Downloading logstash-forwarder key from ${LSF_KEY_URL}"
  curl -Ls -o ${LSF_KEY_FILE} ${LSF_KEY_URL}
  if [ $? -ne 0 ]; then
    echo "[logstash] Failed to download ${LSF_KEY_URL} exiting."
    exit 1
  fi
fi

# Create a new SSL certificate for Logstash-Forwarder if needed
if [ ! -f "$LSF_KEY_FILE" ]; then
  echo "[logstash] Generating new logstash-forwarder key"
  openssl req -x509 -batch -nodes -newkey rsa:4096 -keyout "$LSF_KEY_FILE" -out "$LSF_CERT_FILE"
fi

# Check config file
${LS_HOME}/bin/logstash agent -t -f ${LS_CFG_FILE}
if [ $? -ne 0 ]; then
  echo "[logstash] Invalid logstash.conf file, exiting."
  exit 1
fi

# Run process, if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  exec ${LS_HOME}/bin/logstash agent -f ${LS_CFG_FILE} "$@"
fi

# As argument is not Logstash, assume user wants to run his own process, for example a shell to explore this image
exec "$@"
