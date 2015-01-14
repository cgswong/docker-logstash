## Logstash Dockerfile

This repository contains a **Dockerfile** of [Logstash](http://www.elasticsearch.org/) for [Docker's](https://www.docker.com/) [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an Elasticsearch instance (search database) and Kibana (as a frontend). Current Logstash version used is 1.4.2

### Base Docker Image

* [dockerfile/java:oracle-java7](http://dockerfile.github.io/#/java)

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull cgswong/logstash`

   (alternatively, you can build an image from Dockerfile: `docker build -t="cgswong/logstash" github.com/cgswong/docker-logstash`)

### Usage
Logstash is set to listen on TCP port **5000** for lines of **JSON**, and port **5010** for **syslog** along with the local syslog files.You would typically link this container to an Elasticsearch container (alias **es**) that exposes port **9200**. The default `logstash.conf` file uses the Docker linked container environment placeholder **ES_PORT_9200_TCP_ADDR** when using a linked Elasticsearch container. This relies on using the default TCP port (9200) with a container alias of **es**.

The environment variable `ES_CLUSTER_NAME` should be set to the name of the Elasticsearch container (must match the name used in the Elasticsearch configuration file). This can be set using the `-e` flag when executing `docker run`. The default is `es_cluster01`.

You can use your own configuration file by:

- Setting the `-v` flag when executing `docker run` to mount your own configuration file via the exposed `/opt/logstash/conf` volume.

- Overriding the **LOGSTASH_CFG_URI** environment variable which is set using the `-e` flag when executing `docker run`. This will download, via wget, your configuration file.

To run logstash and connect to a linked Elasticsearch container (which should ideally be started first):
```sh
docker run -d --link elasticsearch:es -p 9200:9200 -p 5000:5000 --name logstash cgswong/logstash
```
