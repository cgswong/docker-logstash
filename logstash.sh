#! /bin/bash
# #################################################################
# NAME: logstash.sh
# DESC: Logstash startup file.
#
# LOG:
# yyyy/mm/dd [user] [version]: [notes]
# 2014/10/23 cgwong v0.1.0: Initial creation
# 2014/10/23 cgwong v0.1.1: Added 'agent' flag. Added commented service call.
# #################################################################

# if `docker run` first argument start with `--` the user is passing launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  /opt/logstash/bin/logstash agent "$@"
  ##sudo service restart logstash
fi

# As argument is not Logstash, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"
