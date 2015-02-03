# ################################################################
# NAME: Dockerfile
# DESC: Docker file to create Logstash container.
#
# LOG:
# yyyy/mm/dd [name] [version]: [notes]
# 2014/10/16 cgwong [v0.1.0]: Initial creation.
# 2014/11/10 cgwong v0.2.0: Included contrib plugins, switched to tar download as a result.
#                           Added new environment variable.
#                           Correct issue with contribs not installing.
# 2014/12/04 cgwong v0.2.1: Switched to version specific. 
#                           Used more environment variables.
#                           Corrected directory bug.
# 2015/01/14 cgwong v0.3.0: General cleanup, added more variable usage.
# 2015/01/28 cgwong v0.4.0: Java 8. Some optimizations to build.
# 2015/02/02 cgwong v1.0.0: Added curl installation, fixed tar issue. Added src directory for complete copy.
# ################################################################

FROM cgswong/java:oracleJDK8
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Setup environment
ENV LS_VERSION 1.4.2
ENV LS_HOME /opt/logstash
ENV LS_CFG_DIR ${LS_HOME}/conf
ENV LS_USER logstash
ENV LS_GROUP logstash
ENV LS_EXEC /usr/local/bin/logstash.sh

# Install Logstash
WORKDIR /opt
RUN apt-get -yq update && DEBIAN_FRONTEND=noninteractive apt-get -yq install curl \
  && apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && curl -s https://download.elasticsearch.org/logstash/logstash/logstash-${LS_VERSION}.tar.gz | tar zxf - \
  && ln -s logstash-${LS_VERSION} logstash \
  && mkdir -p ${LS_CFG_DIR} \

# Configure environment
# Copy in files
COPY src/opt/logstash/conf/logstash.conf ${LS_CFG_DIR}
COPY src/usr/local/bin/logstash.sh /usr/local/bin/

RUN groupadd -r ${LS_GROUP} \
  && useradd -M -r -g ${LS_GROUP} -d ${LS_HOME} -s /sbin/nologin -c "LogStash Service User" ${LS_USER} \
  && chown -R ${LS_USER}:${LS_GROUP} ${LS_EXEC} ${LS_HOME} \
  && chmod +x ${LS_EXEC}

# Listen for JSON connections on HTTP port/interface: 5000
EXPOSE 5000
# Listen for SYSLOG connections on TCP/UDP 5010, RFC3164 format on 5015 and from logstash-forwarder on 5020
EXPOSE 5010 5015 5020
# Listen for Log4j connections on TCP 5025
EXPOSE 5025

##USER ${LS_USER}

# Expose as volume
VOLUME ["${LS_CFG_DIR}"]

CMD ["/usr/local/bin/logstash.sh"]
