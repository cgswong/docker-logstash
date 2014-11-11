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
# ################################################################

FROM dockerfile/java:oracle-java7
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Setup environment
ENV LOGSTASH_VERSION 1.4
ENV LOGSTASH_FULL_VERSION 1.4.2
ENV LOGSTASH_CFG_DIR /opt/logstash/conf

# Install Logstash
RUN wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_VERSION}/debian stable main" >> /etc/apt/sources.list
RUN apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive \
    apt-get -y install wget \
    logstash

WORKDIR /opt
##RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz \
##    && tar -zxf logstash-${LOGSTASH_VERSION}.tar.gz \
##    && rm logstash-${LOGSTASH_VERSION}.tar.gz \
##    && ln -s logstash-${LOGSTASH_VERSION} logstash

# Install contrib plugins
# Repo version has '-modified' attached to version so need below for contrib to install successfully.
RUN sed -e "s/${LOGSTASH_FULL_VERSION}-modified/${LOGSTASH_FULL_VERSION}/" -i /opt/logstash/lib/logstash/version.rb
RUN ["/opt/logstash/bin/plugin", "install", "contrib"]
RUN sed -e "s/${LOGSTASH_FULL_VERSION}/${LOGSTASH_FULL_VERSION}-modified/" -i /opt/logstash/lib/logstash/version.rb

# Listen for connections on HTTP port/interface: 5000
EXPOSE 5000

USER logstash

# Create configuration file location
# Copy in logstash.conf file
# Expose as volume
RUN mkdir -p ${LOGSTASH_CFG_DIR}
COPY conf/logstash.conf ${LOGSTASH_CFG_DIR}/logstash.conf
VOLUME ["${LOGSTASH_CFG_DIR}"]

# Copy in entry script and start 
COPY logstash.sh /usr/local/bin/logstash.sh
ENTRYPOINT ["/usr/local/bin/logstash.sh"]
