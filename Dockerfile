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

# Setup environment
ENV LOGSTASH_VERSION 1.4
##ENV LOGSTASH_VERSION 1.4.2

# Install Logstash
RUN wget -qO - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
RUN echo "deb http://packages.elasticsearch.org/logstash/${LOGSTASH_VERSION}/debian stable main" >> /etc/apt/sources.list
RUN apt-get -y update && apt-get -y install logstash

# Install contrib plugins
##RUN /opt/logstash/bin/plugin install contrib

# Listen for connections on HTTP port/interface: 5000
EXPOSE 5000

USER logstash

# Copy in logstash.conf file.
COPY conf/logstash.conf /opt/logstash/logstash.conf

# Copy in entry script and start 
COPY logstash.sh /usr/local/bin/logstash.sh
ENTRYPOINT ["/usr/local/bin/logstash.sh"]
