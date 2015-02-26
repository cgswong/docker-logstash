## Logstash Dockerfile

This repository contains a **Dockerfile** of [Logstash](http://www.elasticsearch.org/) for [Docker's](https://www.docker.com/) [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an Elasticsearch instance (search database) and Kibana (as a frontend) to form what is known as an *ELK* stack.

### Base Docker Image

* [cgswong/java:orajdk8](https://registry.hub.docker.com/u/cgswong/java/)

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://registry.hub.docker.com/u/cgswong/logstash/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull cgswong/logstash:confd`

   (alternatively, you can build an image from Dockerfile: `docker build -t="cgswong/logstash:confd" github.com/cgswong/docker-logstash`)

### Usage
Logstash is set to listen for:
- _SYSLOG_ on TCP and UDP ports **5000** and **5002** from **logstash-forwarder**
- lines of _JSON_ on TCP port **5100**
- Log4J on TCP port **5200**
- stdin (for testing purposes).

To receive events from **logstash-forwarder** we create a new SSL key pair (if one does not yet exist in our KV store), and store the new certificate and private key in the specified KV store (i.e. either the default etcd or consul). These keys can then be downloaded by any logstash-forwarder process to facilitate configuration. During the systemd startup we register the IP address of Logstash service within the same KV store to make ourselves public to other processes.

This container requires a dependent Elasticsearch container that also registers itself within the same KV store, using the expected keys of:

- `/services/logging/es/host`: IPV4 address of Elasticsearch host (may have port as well in format [host]:[port])
- `/services/logging/es/cluster`: Elasticsearch cluster name

We will wait until those keys present themselves, then use **confd** to update the Logstash configuration file `logstash.conf`, setting those values within the file, then starting Logstash.

**Note: In a production environment a Riak buffer or Kafka queue should be used between Logstash and Elasticsearch to make sure log events are stored in such mechanisms if Elasticsearch is unavailable.**

A systemd unit file is included in this repo which shows how this unit would be started via systemd or Fleet (there is an alternate file for consul). To do a default run using etcd:

```sh
source /etc/environment
docker run --rm --name logstash -e KV_HOST=${COREOS_PRIVATE_IPV4} -P cgswong/logstash:confd
curl -L http://${COREOS_PRIVATE_IPV4}:4001/v2/keys/services/logging/logstash/host/${COREOS_PRIVATE_IPV4} -XPUT -d value="%H"
```

Clean up after stopping: `curl -L http://localhost:4001/v2/keys/services/logging/logstash/host/${COREOS_PRIVATE_IPV4} -XDELETE`

To use consul:
```sh
source /etc/environment
docker run --rm --name logstash -e KV_TYPE=consul -e KV_HOST=${COREOS_PRIVATE_IPV4} -P cgswong/logstash:confd
curl -L http://${COREOS_PRIVATE_IPV4}:8500/v1/kv/services/logging/logstash/host/${COREOS_PRIVATE_IPV4} -XPUT -d value="%H"
```

Clean up after stopping: `curl -L http://${COREOS_PRIVATE_IPV4}:8500/v1/kv/services/logging/logstash/host/${COREOS_PRIVATE_IPV4} -XDELETE`

### Changing Defaults
A few environment variables can be passed via the Docker `-e` flag to do some further configuration:

  - KV_TYPE: Sets the type of KV store to use as the backend. Options are etcd (default) and consul.
  - KV_PORT: Sets the port used in connecting to the KV store which defaults to 4001 for etcd and 8500 for consul.

**Note: The startup procedures previously shown assume you are using CoreOS (with either etcd or consul as your KV store). If you are not using CoreOS then simply substitute the CoreOS specific statements with the appropriate OS specific equivalents.**
