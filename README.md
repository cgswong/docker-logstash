## Logstash Dockerfile

[![Circle CI](https://circleci.com/gh/cgswong/docker-logstash/tree/master.svg?style=svg)](https://circleci.com/gh/cgswong/docker-logstash/tree/master)

This is a highly configurable [Logstash](https://www.elastic.co/products/logstash) (v1.5) Docker image built using [Docker's automated build](https://registry.hub.docker.com/u/cgswong/logstash/) process and published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an [Elasticsearch](https://www.elastic.co/products/elasticsearch) instance (document database) and [Kibana](https://www.elastic.co/products/kibana) (as a frontend) to form what is known as an **ELK stack**.


### How to use this image
#### Simple use case
In the simplest case, to use an external Elasticsearch container with the default `logstash.conf` file set the `ES_CLUSTER` (defaults to `es01`), `ES_HOST` and `ES_PORT` (defaults to 9200) environment variables in the `docker run` command:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env ES_CLUSTER=estest \
  --env ES_HOST=172.17.8.101 \
  --env ES_PORT=9200 \
  cgswong/logstash
```

#### Using local configuration file
You can also mount your own local `logstash.conf` file via the exposed `/etc/logstash/conf.d` volume as follows:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --volume /tmp:/etc/logstash/conf.d
  cgswong/logstash
```

  > In the example above replace _/tmp_ with the path to your own `logstash.conf` file which will be automatically loaded. You can also make use of the variables `ES_CLUSTER`, `ES_HOST` and `ES_PORT` in your file and the values will be substituted when using the environment variables. For example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --volume /tmp:/etc/logstash/conf.d
  --env ES_CLUSTER=estest \
  --env ES_HOST=172.17.8.101 \
  --env ES_PORT=9200 \
  cgswong/logstash
```

#### Using remote configuration file
You can use an external Logstash configuration file which will be downloaded by using the environment variable `LS_CFG_URL`. Within your remote file you can optionally make use of the same variables `ES_CLUSTER`, `ES_HOST` and `ES_PORT` which will be substituted. For example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env LS_CFG_URL=https://gist.githubusercontent.com/cgswong/d34c94aeb90ba91c57b2/raw/a2f55d7916d2fa961826f8db8e1d3482f0f60933/logstash-test.conf
  --env ES_CLUSTER=estest \
  --env ES_HOST=172.17.8.101 \
  --env ES_PORT=9200 \
  cgswong/logstash
```

  > The container must be able to access the URL provided, otherwise it will exit with a failure code.

#### Using Redis
Using [Redis](http://redis.io/) as an output option is supported by setting the `REDIS_HOST` and `REDIS_PORT` (defaults to 6379) environment variables. Similar to `ES_PORT` and `ES_HOST` these variables can be used in your own `logstash.conf` file and the values will be substituted in. For example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env ES_CLUSTER=estest \
  --env ES_HOST=172.17.8.101 \
  --env ES_PORT=9200 \
  --env REDIS_HOST=172.17.8.102 \
  --env REDIS_PORT=6379 \
  cgswong/logstash
```

#### Using Service Discovery
Sample systemd unit files have been provided to show how service discovery could be achieved using this image, assuming the same is being done for the other components in what is likely an ELK stack. The examples use **etcd**, **consul** and **DNS** though there are other options. Below are the expected keys:

- `/services/logging/es/<es_cluster>/proxy`: The key, hostname (preferably) or IPV4 address of the Elasticsearch proxy node in the cluster, would be below this directory. Values include:
  - http_port: HTTP port (default 9200)
  - transport_port: Cluster transport port (default 9300)
  - ipv4: ipv4 of ES proxy node

For doing service discovery involving `etcd` or `consul`, the `KV_TYPE`, `KV_HOST` and `ES_CLUSTER` environment variables must be defined. For example:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env KV_TYPE=etcd
  --env KV_HOST=172.17.8.101
  --env ES_CLUSTER=estest \
  cgswong/logstash
```

The expected key (see above) is watched for any changes so should the ES proxy host/ip change the `logstash.conf` file will be updated and logstash restarted. Please refer to the appropriate example systemd unit file for further details.


### A note about Logstash Forwarder
This image can either use existing SSL keys and certificates, or create new ones for using Logstash-Forwarder. The latter is always done whenever no files are found in the expected location. You can also download your own remote files using the `LSF_CERT_URL` (certificate) and `LSF_KEY_URL` (key) environment variables. See the [Exposed Volumes] section for the location of the files, and the [Service Discovery] section for further information.

  > The container must be able to access all URLs provided, otherwise it will exit with a failure code.


### Exposed Volumes
- `/etc/logstash/conf.d`: Stores the `logstash.conf` file.
- `/etc/logstash/ssl`: Stores SSL certificates, `logstash-forwarder.cert`, and keys, `logstash-forwarder.key`. These are used in a setup involving [Logstash Forwarder](https://github.com/elastic/logstash-forwarder).


### Environment Variables
The following environment variables can be used:

- ES_CLUSTER: Elasticsearch cluster name (mandatory except when using your own configuration file). You can also use this as a substitution variable within your own configuration file as well.
- ES_HOST: Elasticsearch hostname or IPV4 address (mandatory except when using your own configuration file, or Service Discovery). You can also use this as a substitution variable within your own configuration file as well.
- ES_PORT: Elasticsearch HTTP/client port (defaults to 9200). You can also use this as a substitution variable within your own configuration file as well.
- REDIS_HOST: Redis hostname or IPV4 address. You can also use this as a substitution variable within your own configuration file as well.
- REDIS_PORT: Redis connectivity port (defaults to 6379). You can also use this as a substitution variable within your own configuration file as well.
- LS_CFG_URL: URL for remote logstash configuration file. If unable to download the container will fail. Mutually exclusive with `KV_TYPE` as that takes precedence.
- LSF_CERT_URL: URL for logstash-forwarder SSL certificate to download.
- LSF_KEY_URL: URL for logstash-forwarder SSL key to download.
- KV_TYPE: Type of Key/Value store to use for Service Discovery. Currently only **etcd** and **consul** backends are supported. Mutually exclusive with `LS_CFG_URL` and volume mounted `logstash.conf`.
- KV_HOST: Hostname or IPV4 address of Key/Value host for Service Discovery.
- KV_PORT: Port of Key/Value store. Defaults to 4001 for **etcd** and 8500 for **consul**.


### Exposed Ports
The default `logstash.conf` file is set to listen for:

- **syslog**: **5000/tcp** and **5000/udp**
- **Logstash Forwarder**: **5002/tcp**
- **systemd** journals (OS logs): **5004/tcp**
- **JSON lines**: **5100/tcp**
- **Log4J**: **5200/tcp**

> Note that any port within a Docker image must be appropriately exposed (and mapped) on the Docker host. To avoid port conflicts, a _service discovery_ mechanism should be used and the correct hostname/ip and port on the Docker host passed to remote containers/hosts.
