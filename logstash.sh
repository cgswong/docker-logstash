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
# #################################################################

# Set environment variables
LOGSTASH_HOME=${LOGSTASH_HOME:-/opt/logstash}
LOGSTASH_CFG_FILE=${LOGSTASH_CFG_FILE:-"${LOGSTASH_HOME}/conf/logstash.conf"}
ES_CLUSTER_NAME=${ES_CLUSTER_NAME:-"es_cluster01"}
ES_PORT_9200_TCP_ADDR=${ES_PORT_9200_TCP_ADDR:-localhost}
ES_PORT_9200_TCP_PORT=${ES_PORT_9200_TCP_PORT:-9200}

# Use the LOGSTASH_CONFIG_URL env var to download and use custom logstash.conf file.
if [ ! -z $LOGSTASH_CFG_URI ]; then
    echo "Downloading custom configuration file ..."
    wget $LOGSTASH_CONFIG_URI -O $LOGSTASH_CFG_FILE
else
  # Process the linked container env variables.
  sed -e "s/ES_CLUSTER_NAME/${ES_CLUSTER_NAME}/g" -i ${LOGSTASH_CFG_FILE}
  sed -e "s/ES_PORT_9200_TCP_ADDR/${ES_PORT_9200_TCP_ADDR}/g" -i ${LOGSTASH_CFG_FILE}
  sed -e "s/ES_PORT_9200_TCP_PORT/${ES_PORT_9200_TCP_PORT}/g" -i ${LOGSTASH_CFG_FILE}
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  exec ${LOGSTASH_HOME}/bin/logstash agent -f ${LOGSTASH_CFG_FILE} web "$@"
  ##sudo service restart logstash
fi

# As argument is not Logstash, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
