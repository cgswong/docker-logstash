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
# #################################################################

# Set location of logstash configuration file
LOGSTASH_CFG_FILE=${LOGSTASH_CFG_FILE:-/opt/logstash/conf/logstash.conf}

# Use the LOGSTASH_CONFIG_URL env var to download and use custom logstash.conf file.
if [ ! -z $LOGSTASH_CFG_URI ]; then
    echo "Downloading custom configuration file ..."
    wget $LOGSTASH_CONFIG_URI -O $LOGSTASH_CFG_FILE
fi

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  exec /opt/logstash/bin/logstash agent -f ${LOGSTASH_CFG_FILE} web "$@"
  ##sudo service restart logstash
fi

# As argument is not Logstash, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
