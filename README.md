## Logstash Dockerfile

This repository contains a **Dockerfile** of [Logstash](http://www.elasticsearch.org/) for [Docker's](https://www.docker.com/) [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an Elasticsearch instance (search database) and Kibana (as a frontend). Current Logstash version used is 1.4.2

### Base Docker Image

* [cgswong/java:oracleJDK8](https://registry.hub.docker.com/u/cgswong/java/)

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) from public [Docker Hub Registry](https://registry.hub.docker.com/): 

  `docker pull cgswong/logstash`

  (alternatively, you can build an image from Dockerfile:

  `docker build -t="cgswong/logstash" github.com/cgswong/docker-logstash`)

### Usage
Logstash is set to listen for:
- lines of _JSON_ on TCP port **5000**
- _SYSLOG_ on TCP and UDP ports **5010**, **5015** (for RFC3164 format), **5020** (from Logstash Forwarder)
- Log4J on TCP port **5025**
 
Also listens for its local syslog files, and stdin.

You would typically link this container to an Elasticsearch container (alias **es**) that exposes port **9200**. The default `logstash.conf` file uses the Docker linked container environment placeholder **ES_PORT_9200_TCP_ADDR** when using a linked Elasticsearch container. This relies on using the default TCP port (9200) with a container alias of **es**.

The environment variable `ES_CLUSTER_NAME` should be set to the name of the Elasticsearch container (must match the name used in the Elasticsearch configuration file). This can be set using the `-e` flag when executing `docker run`. The default is `es_cluster01`.

You can use your own configuration file by:

- Setting the `-v` flag when executing `docker run` to mount your own configuration file via the exposed `/opt/logstash/conf` volume.

- Overriding the **LOGSTASH_CFG_URI** environment variable which is set using the `-e` flag when executing `docker run` will download, via wget, your configuration file.

To run logstash and connect to a linked Elasticsearch container (which should ideally be started first):

```sh
docker run -d --link elasticsearch:es -p 5000:5000 -p 5010:5010 -p 5015:5015 -p 5020:5020 --name logstash cgswong/logstash
```

### Validation Testing
To test the setup you will need to send some data to the Logstash container. This can be done as shown below:

```sh
curl -XPOST <container_host>:9200/logstash-2015.01.07/logs/1 -d '{"@timestamp": "2015-01-07T20:11:45.000Z","@version": "1","count": 2048,"average": 1523.33,"host": "elasticsearch.com"}'
```

You can also send some test data using:

```sh
echo '{"@timestamp": "2015-01-07T20:11:45.000Z","@version": "1","count": 2048,"average": 1523.33,"host": "elasticsearch.com"}' | nc -w 1  <container_host> 5000
```

To verify the indexes have been created in your Elasticsearch instance:

```sh
curl -s http://<container_host>:9200/_status?pretty=true
```

The data should also be available in your Kibana dashboard. Ensure the same date/time period is used when searching as was done in the sample commands.
