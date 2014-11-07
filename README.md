## Logstash Dockerfile

This repository contains **Dockerfile** of [Logstash](http://www.elasticsearch.org/) for [Docker](https://www.docker.com/)'s [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).
It is usually paired with an Elasticsearch (as a search database) and Kibana (as a frontend). Current Logstash version used is 1.4.2

### Base Docker Image

* [dockerfile/java:oracle-java7](http://dockerfile.github.io/#/java)

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull cgswong/logstash`

   (alternatively, you can build an image from Dockerfile: `docker build -t="cgswong/logstash" github.com/cgswong/docker-logstash`)

### Usage

```sh
docker run -d -p 5000:5000 cgswong/logstash
```

It listens on TCP port 5000 for lines of JSON. You would typically link this to an Elasticsearch container (alias ES) that exposes port 9200.
