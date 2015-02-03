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
# #################################################################

# Set environment variables
LS_HOME=${LS_HOME:-/opt/logstash}
LS_CFG_FILE=${LS_CFG_FILE:-"$LS_HOME/conf/logstash.conf"}
ES_CLUSTER_NAME=${ES_CLUSTER_NAME:-"es_cluster01"}
ES_PORT_9200_TCP_ADDR=${ES_PORT_9200_TCP_ADDR:-localhost}
ES_PORT_9200_TCP_PORT=${ES_PORT_9200_TCP_PORT:-9200}

# Use the LS_CONFIG_URI env var to download and use custom logstash.conf file.
if [ ! -z $LS_CFG_URI ] ; then
    wget $LS_CONFIG_URI -O $LS_CFG_FILE
else
  # Process the linked container env variables.
  sed -e "s/ES_CLUSTER_NAME/${ES_CLUSTER_NAME}/g" -i ${LS_CFG_FILE}
  sed -e "s/ES_PORT_9200_TCP_ADDR/${ES_PORT_9200_TCP_ADDR}/g" -i ${LS_CFG_FILE}
  sed -e "s/ES_PORT_9200_TCP_PORT/${ES_PORT_9200_TCP_PORT}/g" -i ${LS_CFG_FILE}
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  exec ${LS_HOME}/bin/logstash -f ${LS_CFG_FILE} "$@"
##  exec ${LS_HOME}/bin/logstash agent -f ${LS_CFG_FILE} web "$@"
  ##sudo service restart logstash
fi

# As argument is not Logstash, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
