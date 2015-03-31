## Logstash Dockerfile
This is a highly configurable [Logstash](https://www.elastic.co/products/logstash) (v1.5rc2) Docker image built using [Docker's automated build](https://registry.hub.docker.com/u/cgswong/logstash/) process and published to the public [Docker Hub Registry](https://registry.hub.docker.com/).

It is usually paired with an [Elasticsearch](https://www.elastic.co/products/elasticsearch) instance (document database) and [Kibana](https://www.elastic.co/products/kibana) (as a frontend) to form what is known as an **ELK stack**.


### How to use this image
In the simplest case, to use an external Elasticsearch container with the default `logstash.conf` file set the `LS_CFG_USE`, `ES_CLUSTER`, `ES_HOST` and `ES_PORT` (defaults to 9200) environment variables in the `docker run` command:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env LS_CFG_USE=int \
  --env ES_CLUSTER=<es_service_cluster> \
  --env ES_HOST=<es_service_host> \
  --env ES_PORT=<es_service_port> \
  cgswong/logstash
```

[Redis](http://redis.io/) is typically used in larger (production) ELK deployments as a queue or buffer mechanism between log shippers/forwarders and a central Logstash instance. This provides better scale, and guards against losing logs should your central Logstash instance be offline. A Redis output option is provided in the image's default `logstash.conf` file. To use Redis and the default `logstash.conf` file set the `LS_CFG_USE`, `REDIS_HOST` and `REDIS_PORT` (defaults to 6379) environment variables in the `run` command:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env LS_CFG_USE=int \
  --env REDIS_HOST=<redis_service_host> \
  --env REDIS_PORT=<redis_service_port> \
  cgswong/logstash
```

To combine both output options you would include all environment variables in your `run` command:

```sh
docker run -d \
  --publish 5000:5000 \
  --publish 5000:5000/udp \
  --publish 5002:5002 \
  --publish 5004:5004 \
  --publish 5100:5100 \
  --publish 5200:5200 \
  --env LS_CFG_USE=int \
  --env ES_CLUSTER=<es_service_cluster> \
  --env ES_HOST=<es_service_host> \
  --env ES_PORT=<es_service_port> \
  --env REDIS_HOST=<redis_service_host> \
  --env REDIS_PORT=<redis_service_port> \
  cgswong/logstash
```

> Note that this image does a check of any provided `logstash.conf` file and exits with an error status should that check fail.


### Using external configuration files
The image supports using an external configuration file using:

- Docker host volume mounts using `-v` Docker command line option. The `logstash.conf` file is stored in the exposed directory `/etc/logstash/conf.d`. The [Logstash Forwarder](https://github.com/elastic/logstash-forwarder) directory `/opt/logstash/ssl` is used to store the SSL certificates (`logstash-forwarder.cert`), and keys (`logstash-forwarder.key`). The `LS_CFG_USE` environment variable **must** be set to some value to use your volume mounted file.

- File download URL using:

  - LS_CFG_URL: URL pointing to logstash.conf file
  - LSF_CERT_URL: URL pointing to Logstash Forwarder certificate
  - LSF_KEY_URL: URL pointing to Logstash Forwarder key

  > The container must be able to access any URL provided, otherwise it will exit with a failure code. You can also use the other environment variables (`ES_CLUSTER`, `ES_HOST`, `ES_PORT`, `REDIS_HOST`, `REDIS_PORT`) within your download file as placeholders and their values, as specified on the `docker run` command line, will be injected into your configuration file.

> Note: A Logstash Forwarder certificate and key will be created if a key file is not present in the location expected, i.e. exposed volume `/etc/logstash/ssl/logstash-forwarder.key`. This filename can be changed using the `LSF_KEY_FILE` environment variable.


### Ports
The default `logstash.conf` file is set to listen for:

- **syslog**: **5000/tcp** and **5000/udp**
- **Logstash Forwarder**: **5002/tcp**
- **systemd** journals (OS logs): **5004/tcp**
- **JSON lines**: **5100/tcp**
- **Log4J**: **5200/tcp**

> Note that any port within a Docker image must be appropriately exposed (and mapped) on the Docker host. To avoid port conflicts, a _service discovery_ mechanism must be used and the correct hostname/ip and port on the Docker host passed to remote containers/hosts.

### Doing Service Discovery
Sample systemd unit files have been provided to show how service discovery could be achieved using this image, assuming the same is being done for the other components in the ELK stack. The examples use etcd and consul as the service registries though there are other options including DNS discovery. Below are the expected KV using etc or consul.

- `/services/logging/logstash/host`: The key, hostname (preferrably) or IPV4 address of Logstash host, would be below this directory.
- `/services/logging/es/<es_cluster>/host`: The key, hostname (preferrably) or IPV4 address of each Elasticsearch data node in the specified cluster, would be below this directory. Values would include:
  - http_port: HTTP port (default 9200)
  - transport_port: Cluster transport port (default 9300)
  - host/ipv4: Hostname/ipv4 of specific ES cluster member
- `/services/logging/es/<es_cluster>/proxy`: The key, hostname (preferrably) or IPV4 address of the Elasticsearch proxy node in the specified cluster, would be below this directory. Values would be same as the data nodes.

A side load unit would be used to dynamically update the appropriate key/values based on health checks.

Please refer to the appropriate example systemd unit file for further details.
