# ################################################################
# NAME: Dockerfile
# DESC: Docker file to create Logstash container.
#
# LOG:
# yyyy/mm/dd [name] [version]: [notes]
# 2014/10/16 cgwong [v0.1.0]: Initial creation.
# ################################################################

FROM dockerfile/java:oracle-java7
MAINTAINER Stuart Wong <cgs.wong@gmail.com>

# Install Logstash
ENV LOGSTASH_VERSION 1.4
##ENV LOGSTASH_VERSION 1.4.2
##RUN wget https://download.elasticsearch.org/logstash/logstash/logstash-${LOGSTASH_VERSION}.tar.gz && \
##  tar zxf logstash-${LOGSTASH_VERSION}.tar.gz && rm -f logstash-${LOGSTASH_VERSION}.tar.gz && ln -s logstash-${LOGSTASH_VERSION} logstash
RUN wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_VERSION}/debian stable main" >> /etc/apt/sources.list
RUN apt-get -y update && apt-get -y install logstash

# Install contrib plugins
RUN /opt/logstash/bin/plugin install contrib

# Copy in logstash.conf file.
COPY config/logstash.conf /opt/logstash/logstash.conf

COPY run.sh /usr/local/bin/run.sh
USER logstash
CMD ["/usr/local/bin/run.sh"]

# Listen on HTTP interface/port: 5000
EXPOSE 5000
