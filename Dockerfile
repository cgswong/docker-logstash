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
# 2015/03/25 cgwong v1.1.0: Update to 1.5.0rc2, add confd.
# ################################################################

FROM cgswong/java:orajdk8
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Setup environment
ENV LS_VERSION 1.5.0.rc2
ENV LS_HOME /opt/logstash
ENV LS_CFG_DIR /etc/logstash/conf.d
ENV LS_USER logstash
ENV LS_GROUP logstash
ENV LS_EXEC /usr/local/bin/logstash.sh
ENV LS_SSL /etc/logstash/ssl
ENV CONFD_VERSION 0.7.1

# Install Logstash
WORKDIR /opt
RUN apt-get -yq update && DEBIAN_FRONTEND=noninteractive apt-get -yq install \
  curl \
  supervisor \
  && apt-get -y clean && apt-get -y autoclean && apt-get -y autoremove \
  && rm -rf /var/lib/apt/lists/* \
  && curl -s https://download.elasticsearch.org/logstash/logstash/logstash-${LS_VERSION}.tar.gz | tar zxf - \
  && ln -s logstash-${LS_VERSION} logstash \
  && mkdir -p ${LS_CFG_DIR} ${LS_SSL} \
  && curl -sL -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 \
  && chmod +x /usr/local/bin/confd

# Configure environment
# Copy in files
COPY src/ /

RUN groupadd -r ${LS_GROUP} \
  && useradd -M -r -g ${LS_GROUP} -d ${LS_HOME} -s /sbin/nologin -c "LogStash Service User" ${LS_USER} \
  && chown -R ${LS_USER}:${LS_GROUP} ${LS_EXEC} ${LS_HOME}/ ${LS_CFG_DIR} ${LS_SSL} \
  && chmod +x ${LS_EXEC}

# Listen for SYSLOG on tcp/udp:5000, logstash-forwarder on tcp:5002, systemd journal on tcp:5004, JSON on tcp:5100, Log4j on tcp:5200
EXPOSE 5000 5002 5004 5100 5200

#USER ${LS_USER}

# Expose as volume
VOLUME ["${LS_CFG_DIR}", "${LS_SSL}"]

CMD ["/usr/local/bin/logstash.sh"]
