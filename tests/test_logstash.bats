#!/usr/bin/env bats

setup() {
  # Setup environment
  SLEEP=8
  host=$(echo $DOCKER_HOST|cut -d":" -f2|sed -e 's/\/\///')

  # Launch required ES container
  docker run -d --name eslogstash -P cgswong/elasticsearch:latest >/dev/null
  es_port=$(docker port eslogstash | grep 9200 | cut -d":" -f2)
  es_url="http://${host}:${es_port}"

  sleep $SLEEP

  # Launch container
  docker run -d --name ${IMAGE} -P --env LS_ES_HOST=$(echo $es_url | cut -d'/' -f3) ${IMAGE}:${TAG} >/dev/null
  port=$(docker port ${IMAGE} | grep 5000 | cut -d":" -f2)
  url="http://${host}:${port}"
}

teardown () {
  # Cleanup
  docker stop ${IMAGE} >/dev/null
  docker rm ${IMAGE} >/dev/null
  docker stop eslogstash >/dev/null
  docker rm eslogstash >/dev/null
}

@test "Confirm Logstash is available" {
  sleep $SLEEP
  run curl --retry 10 --retry-delay 5 --silent --output /dev/null --location --head --write-out "%{http_code}" $url
  [ $status -eq 0 ]
  [[ "$output" =~ "200" ]]
}

@test "Confirm Logstash version ${TAG}" {
  sleep $SLEEP
  run docker run -t --rm --name ${IMAGE} -P ${IMAGE}:${TAG} /opt/logstash/bin/logstash --help
  [[ "$output" =~ "KIBANA_VERSION='${TAG}'" ]]
}
