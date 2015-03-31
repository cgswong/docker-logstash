#! /bin/bash
# #################################################################
# NAME: logstash.sh
# DESC: Logstash startup file.
#
# LOG:
# yyyy/mm/dd [user] [version]: [notes]
# 2014/10/23 cgwong v0.1.0: Initial creation
# 2014/11/07 cgwong v0.1.1: Added 'agent' flag.
#                           Added commented service call.
#                           Added -f <config_file> flag.
# 2014/11/10 cgwong v0.1.2: Added environment variable for configuration file.
#                           Added download option for configuration file.
# 2014/11/11 cgwong v0.2.0: Added further environment variables.
# 2014/12/04 cgwong v0.2.1: Added further environment variable.
# 2015/01/14 cgwong v0.3.0: Use variable short forms.
#                           Remove 'agent' and 'web' options in preparation for v1.5 change.
# 2015/03/25 cgwong v1.0.0: Refactor.
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

createKey() {
  # Create a new SSL certificate for Logstash-Forwarder if needed
  if [ ! -f "$LSF_KEY_FILE" ]; then
    echo "[logstash] Generating new logstash-forwarder key"
    openssl req -x509 -batch -nodes -newkey rsa:4096 -keyout "$LSF_KEY_FILE" -out "$LSF_CERT_FILE"
  fi
}

# Download the config file, if given a URL
if [ ! -z "$LS_CFG_URL" ]; then
  echo "[logstash] Downloading logstash config file from ${LS_CFG_URL}"
  curl -Ls -o ${LS_CFG_FILE} ${LS_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[logstash] Failed to download ${LS_CFG_URL} exiting."
    exit 1
  fi

  # Update logstash.conf file with needed info
  sed -ie "s/ES_CLUSTER/${ES_CLUSTER}/" $LS_CFG_FILE
  sed -ie "s/ES_HOST/${ES_HOST}/" $LS_CFG_FILE
  sed -ie "s/ES_PORT/${ES_PORT}/" $LS_CFG_FILE
  sed -ie "s/REDIS_HOST/${REDIS_HOST}/" $LS_CFG_FILE
  sed -ie "s/REDIS_PORT/${REDIS_PORT}/" $LS_CFG_FILE

  # Download SSL cert if given a URL
  if [ ! -z "$LSF_CERT_URL" ]; then
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

  createKey

  # Check/validate config file
  ${LS_HOME}/bin/logstash agent -t -f ${LS_CFG_FILE}
  if [ $? -ne 0 ]; then
    echo "[logstash] Invalid logstash.conf file, exiting."
    exit 1
  fi
elif [ -z "$LS_CFG_USE" ]; then
  # Use service discovery
  KV_TYPE=${KV_TYPE:-etcd}
  KV_HOST=${KV_HOST:-127.0.0.1}
  if [ "$KV_TYPE" = "etcd" ]; then
    # Set as default for etcd unless otherwise stated
    KV_PORT=${KV_PORT:-4001}
  else
    # Set as default for consul unless otherwise stated
    KV_PORT=${KV_PORT:-8500}
  fi
  KV_URL=${KV_HOST}:${KV_PORT}

  # Update ES_CLUSTER resources
  sed -ie "s/es01/$ES_CLUSTER/g" /etc/confd/conf.d/logstash.toml
  sed -ie "s/es01/$ES_CLUSTER/g" /etc/confd/templates/logstash.conf.tmpl

  echo "[logstash] booting container using $KV_TYPE KV backend"

  # Loop every 5 seconds until confd has updated the logstash config
  until confd -onetime -backend $KV_TYPE -node $KV_URL -config-file /etc/confd/conf.d/logstash.toml; do
    echo "[logstash] waiting for confd to refresh logstash.conf (waiting for ElasticSearch to be available)"
    sleep 5
  done

  # Put continual polling on `confd` process in the background to watch for any changes every 10 seconds.
  confd -interval 10 -backend $KV_TYPE -node $KV_URL -config-file /etc/confd/conf.d/logstash.toml &
  echo "[logstash] confd is now monitoring $KV_TYPE for any changes..."

  createKey

  # Publish SSL cert/key to KV store
  if [ "$KV_TYPE" == "etcd" ]; then
    # Etcd as KV store
    curl -L $KV_URL/v2/keys/services/logging/logstash/ssl_certificate -XPUT --data-urlencode value@${LS_SSL}/logstash-forwarder.crt
    curl -L $KV_URL/v2/keys/services/logging/logstash/ssl_private_key -XPUT --data-urlencode value@${LS_SSL}/logstash-forwarder.key
  else
    # Assume it's consul KV otherwise
    curl -L $KV_URL/v1/kv/services/logging/logstash/ssl_certificate -XPUT --data-urlencode @${LS_SSL}/logstash-forwarder.crt
    curl -L $KV_URL/v1/kv/services/logging/logstash/ssl_private_key -XPUT --data-urlencode @${LS_SSL}/logstash-forwarder.key
  fi
fi

# Run process, if `docker run` first argument start with `--` the user is passing launcher arguments
if [ $# -lt 1 ]; then
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
else
  # As argument is not Logstash, assume user wants to run his own process, for example a shell to explore this image
  exec "$@"
fi
