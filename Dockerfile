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
# 2015/01/014 cgwong v0.3.0: General cleanup, added more variable usage.
# ################################################################

FROM dockerfile/java:oracle-java7
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Setup environment
ENV LS_VERSION 1.4.2
ENV LS_BASE /opt
ENV LS_HOME ${LS_BASE}/logstash
ENV LS_CFG_DIR ${LS_HOME}/conf
ENV LS_USER logstash
ENV LS_GROUP logstash
ENV LS_GROUP logstash
ENV LS_EXEC /usr/local/bin/logstash.sh

# Install Logstash
WORKDIR ${LS_BASE}
RUN curl -s https://download.elasticsearch.org/logstash/logstash/logstash-${LS_VERSION}.tar.gz | tar zx -C ${LS_BASE} \
  && ln -s logstash-${LS_VERSION} logstash

# Install contrib plugins
RUN ${LS_HOME}/bin/plugin install contrib

# Configure environment
RUN groupadd -r ${LS_GROUP} \
  && useradd -M -r -g ${LS_GROUP} -d ${LS_HOME} -s /sbin/nologin -c "LogStash Service User" ${LS_USER} \
  && chown -R ${LS_USER}:${LS_GROUP} logstash-${LS_VERSION}

# Listen for connections on HTTP port/interface: 5000
EXPOSE 5000

USER ${LS_USER}

# Create configuration file location
# Copy in logstash.conf file
# Expose as volume
RUN mkdir -p ${LS_CFG_DIR}
COPY conf/logstash.conf ${LS_CFG_DIR}/logstash.conf
VOLUME ["${LS_CFG_DIR}"]

# Copy in entry script and start 
COPY logstash.sh ${LS_EXEC}
RUN chmod +x ${LS_EXEC}
ENTRYPOINT ["$LS_EXEC"]
