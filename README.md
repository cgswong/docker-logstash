## Logstash Dockerfile

This repository contains a **Dockerfile** of [Logstash](http://www.elasticsearch.org/) for [Docker's](https://www.docker.com/) [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an Elasticsearch instance (search database) and Kibana (as a frontend). Current Logstash version used is 1.4.2

### Base Docker Image

* [cgswong/java:oraclejdk8](https://registry.hub.docker.com/u/cgswong/java/)

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull cgswong/logstash`

   (alternatively, you can build an image from Dockerfile: `docker build -t="cgswong/logstash" github.com/cgswong/docker-logstash`)

### Usage
Logstash is set to listen for:
- lines of _JSON_ on TCP port **5000**
- _SYSLOG_ on TCP and UDP ports **5010**, **5020** (from **logstash-forwarder**)
- Log4J on TCP port **5025**
- stdin (for testing purposes).

To receive events from **logstash-forwarder** we create a new SSL key pair (if one does not yet exist in our KV store), and store the new certificate and private key in the specified KV store (i.e. either the default etcd or consul). These keys can then be downloaded by any logstash-forwarder process to facilitate configuration. During the systemd startup we register the IP address of Logstash service within the same KV store to make ourselves public to other processes.

This container requires a dependent Elasticsearch container (alias **es**) that also registers itself within the same KV store, using the expected keys of:

- `/es/host`: IPV4 address of Elasticsearch host (may have port as well in format [host]:[port])
- `/es/cluster`: Elasticsearch cluster name

We will wait until those keys present themselves, then use **confd** to update the Logstash configuration file `logstash.conf`, setting those values within the file, then starting Logstash.

**Note: In a production environment a Redis buffer or Kafka queue should be used between Logstash and Elasticsearch to make sure log events are stored in such mechanisms if Elasticsearch is unavailable.**

A systemd unit file is included (here)[https://github.com/cgswong/docker-logstash/blob/confd/systemd/logstash.service], which shows how this unit would be started via Fleet. Both options using the default etcd and optional consul (commented) KV store are presented. To do a default run (i.e. using etcd):

```sh
source /etc/environment
docker run --rm --name logstash -e KV_HOST=${COREOS_PUBLIC_IPV4} -p 5000:5000 -p 5010:5010 -p 5020:5020 -p 5025:5025 cgswong/logstash
etcdctl set /logstash/host ${COREOS_PUBLIC_IPV4}
```

Clean up after stopping: `etcdctl rm --dir --recursive /logstash`

To use consul:
```sh
source /etc/environment
docker run --rm --name logstash -e KV_TYPE=consul -e KV_HOST=${COREOS_PUBLIC_IPV4} -p 5000:5000 -p 5010:5010 -p 5020:5020 -p 5025:5025 cgswong/logstash
curl -X PUT -d ${COREOS_PUBLIC_IPV4} http://${COREOS_PUBLIC_IPV4}:8500/v1/kv/logstash/host
```

Clean up after stopping: `curl -X DELETE http://${COREOS_PUBLIC_IPV4}:8500/v1/kv/logstash/?recurse`

**Note: The startup procedures previously shown assume you are using CoreOS (with either etcd or consul as your KV store). If you are not using CoreOS then simply substitute the `source /etc/environment` and `${COREOS_PUBLIC_IPV4}` statements with the appropriate OS specific equivalents.**
