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

# Fail fast, including pipelines
set -eo pipefail

# Logstash setup
LS_HOME="/opt/logstash"
LS_CFG_FILE=${LS_CFG_FILE:-"/etc/logstash/conf.d/logstash.conf"}

# Logstash-Forwarder setup
LSF_CERT_FILE=${LSF_CERT_FILE:-"/etc/logstash/ssl/logstash-forwarder.crt"}
LSF_KEY_FILE=${LSF_KEY_FILE:-"/etc/logstash/ssl/logstash-forwarder.key"}

# Elasticsearch setup
ES_CLUSTER=${ES_CLUSTER:-"es01"}

# Use linked ES container if exist, otherwise ES_HOST if defined, else fall back to localhost
ES_HOST=${ES_HOST:-"localhost"}
ES_HOST=${ES_PORT_9200_TCP_ADDR:-$ES_HOST}

# Use linked ES container if exist, otherwise ES_PORT if defined, else fall back to 9200
ES_PORT=${ES_PORT:-"9200"}
ES_PORT=${ES_PORT_9200_TCP_PORT:-$ES_PORT}

REDIS_HOST=${REDIS_HOST:-"localhost"}
REDIS_PORT=${REDIS_PORT:-"6379"}

createKey() {
# Create a new SSL certificate for Logstash-Forwarder if needed
  if [ ! -f "$LSF_KEY_FILE" ]; then
    echo "[logstash] Generating new logstash-forwarder key"
    openssl req -x509 -batch -nodes -newkey rsa:4096 -keyout "$LSF_KEY_FILE" -out "$LSF_CERT_FILE"
  fi
}

downloadLogstashConfig() {
  # Download the config file, if given a URL
  if [ ! -z "$LS_CFG_URL" ]; then
    echo "[logstash] Downloading logstash config file from ${LS_CFG_URL}"
    curl -Ls -o ${LS_CFG_FILE} ${LS_CFG_URL}
    if [ $? -ne 0 ]; then
      echo "[logstash] Failed to download ${LS_CFG_URL} exiting."
      exit 1
    fi
  fi
}

downloadLSFConfig() {
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
}

SanitizeLogstashConfig() {
  # Update logstash.conf file with needed info if they exist
  sed -e "s|ES_CLUSTER|${ES_CLUSTER}|g" \
      -e "s|ES_HOST|${ES_HOST}|g" \
      -e "s|ES_PORT|${ES_PORT}|g" \
      -e "s|REDIS_HOST|${REDIS_HOST}|g" \
      -e "s|REDIS_PORT|${REDIS_PORT}|g" \
      -i "$LS_CFG_FILE"
}

validateLogstashConfig() {
  # Check/validate config file
  ${LS_HOME}/bin/logstash agent -t -f ${LS_CFG_FILE}
  if [ $? -ne 0 ]; then
    echo "[logstash] Invalid ${LS_CFG_FILE} file, exiting."
    exit 1
  fi
}

configKV() {
# Use service discovery

  SVC_URL_BASE="services/logging/logstash"
  LS_CONFD_CFG="/etc/confd/conf.d/logstash.toml"
  LS_CONFD_TMPL="/etc/confd/templates/logstash.conf.tmpl"

  if [ ! -z "$KV_TYPE" ]; then
    KV_TYPE=${KV_TYPE:-etcd}
    KV_HOST=${KV_HOST:-127.0.0.1}
    if [ "$KV_TYPE" = "etcd" ]; then
      # Set as default for etcd unless otherwise stated
      KV_PORT=${KV_PORT:-4001}
      KV_URL=${KV_HOST}:${KV_PORT}

      # Publish SSL cert/key to KV store
      curl -L $KV_URL/v2/keys/${SVC_URL_BASE}/ssl_certificate -XPUT --data-urlencode value@${LSF_CERT_FILE}
      curl -L $KV_URL/v2/keys/${SVC_URL_BASE}/ssl_private_key -XPUT --data-urlencode value@${LSF_KEY_FILE}
    elif [ "$KV_TYPE" = "consul" ]; then
      # Set as default for consul unless otherwise stated
      KV_PORT=${KV_PORT:-8500}
      KV_URL=${KV_HOST}:${KV_PORT}

      # Publish SSL cert/key to KV store
      curl -L $KV_URL/v1/kv/${SVC_URL_BASE}/ssl_certificate -XPUT --data-urlencode @${LSF_CERT_FILE}
      curl -L $KV_URL/v1/kv/${SVC_URL_BASE}/ssl_private_key -XPUT --data-urlencode @${LSF_KEY_FILE}
    else
      echo "[logstash] Invalid KV_TYPE specified, valid values are etcd and consul."
      exit 1
    fi

    # Update ES_CLUSTER resources
    sed -ie "s|es01|${ES_CLUSTER}|g" ${LS_CONFD_CFG}
    sed -ie "s|es01|${ES_CLUSTER}|g" ${LS_CONFD_TMPL}

    echo "[logstash] booting container using $KV_TYPE KV backend"

    # Loop every 5 seconds until confd has updated the logstash config
    until confd -onetime -backend $KV_TYPE -node $KV_URL -config-file $LS_CONFD_CFG; do
      echo "[logstash] waiting for confd to refresh logstash.conf (waiting for ElasticSearch to be available)"
      sleep 5
    done

    # Put continual polling on `confd` process in the background to watch for any changes every 10 seconds.
    confd -interval 10 -backend $KV_TYPE -node $KV_URL -config-file $LS_CONFD_CFG &
    echo "[logstash] confd is now monitoring $KV_TYPE for any changes..."
  fi
}

downloadLogstashConfig
SanitizeLogstashConfig
downloadLSFConfig
createKey
configKV

# Run process, if `docker run` first argument start with `--` the user is passing launcher arguments
if [ $# -lt 1 ]; then
  /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
else
  # As argument is not Logstash, assume user wants to run his own process, for example a shell to explore this image
  exec "$@"
fi
