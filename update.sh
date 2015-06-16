#!/usr/local/bin/bash
# ###################################################
# DESC.: Update Dockerfile for each version directory.
#        Show some information on each version.
# ###################################################
#set -e

declare -A aliases
aliases=(
  [1.5.0]='latest'
)

# Script directory
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( 1.*/ )
versions=( "${versions[@]%/}" )
downloadable=$(curl --insecure --location --silent --show-error 'https://www.elastic.co/downloads/past-releases'   | sed -rn 's!.*?/downloads/past-releases/(logstash-)?[0-9]+-[0-9]+-[0-9]+">Logstash ([0-9]+\.[0-9]+\.[0-9]+)<.*!\2!gp')
url='git://github.com/cgswong/docker-logstash'

for version in "${versions[@]}"; do
  recent=$(echo "$downloadable" | grep -m 1 "$version")
  sed 's/%%VERSION%%/'"$recent"'/' <Dockerfile.tpl >"$version/Dockerfile"
  cp -R src $version/

  commit="$(git log -1 --format='format:%H' -- "$version")"
  fullVersion="$(grep -m1 'ENV LS_VERSION' "$version/Dockerfile" | cut -d' ' -f3)"

  versionAliases=()
  while [ "$fullVersion" != "$version" -a "${fullVersion%[-]*}" != "$fullVersion" ]; do
    versionAliases+=( $fullVersion )
    fullVersion="${fullVersion%[-]*}"
  done
  versionAliases+=( $version ${aliases[$version]} )

  for va in "${versionAliases[@]}"; do
    echo "$va: ${url}@${commit} $version"
  done
done
