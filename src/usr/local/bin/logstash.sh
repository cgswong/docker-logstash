#!/usr/bin/bash
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
# 2015/02/23 cgwong v0.5.0: Use supervisord with etcd and confd to run across different hosts using service discovery.
# #################################################################

# Fail hard and fast
set -eo pipefail

# Set environment variables
LS_HOME=${LS_HOME:-/opt/logstash}
LS_CFG_FILE=${LS_CFG_FILE:-"/etc/logstash/conf.d/logstash.conf"}

KV_TYPE=${KV_TYPE:-etcd}
KV_HOST=${KV_HOST:-localhost}
if [ "$KV_TYPE" = "etcd" ]; then
  # Set as default for etcd unless otherwise stated
  KV_PORT=${KV_PORT:-4001}
else
  # Set as default for consul unless otherwise stated
  KV_PORT=${KV_PORT:-8500}
fi
KV_URL=${KV_HOST}:${KV_PORT}

echo "[logstash] booting container. KV store: $KV_TYPE"

sed -ie "s/-backend etcd -node 127.0.0.1:4001/-backend ${KV_TYPE} -node ${KV_URL}/" /etc/supervisor/conf.d/confd.conf

# Loop until confd has updated the logstash config
until confd -onetime -backend $KV_TYPE -node $KV_URL -config-file /etc/confd/conf.d/logstash.toml; do
  echo "[logstash] waiting for confd to refresh logstash.conf (waiting for ElasticSearch to be available)"
  sleep 5
done

# Run main process
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# As argument is not Logstash, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
