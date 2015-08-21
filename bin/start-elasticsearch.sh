#!/bin/bash

set -x

function create_consul_session() {
  sed -i "s/<HOST>/$HOST/" /elasticsearch/etc/consul_session.json
  curl -s -XPUT -d @consul_session.json http://consul:8500/v1/session/create | jq -r ".ID"
}

function add_consul_key() {
  curl -s -XPUT -d $IP http://consul:8500/v1/kv/elasticsearch/cluster/nodes/${IP}?acquire=$SESSION_ID
}

function wait_for_nodes() {
  local hosts
  local count
  keys="$(curl -s -XGET http://consul:8500/v1/kv/elasticsearch/cluster/nodes?recurse | jq -r '.[] | .Key')"

  ## wait for 1 minute for all nodes to register 
  while [[ $(echo $keys | wc -w | awk '{print $1}') -lt 3 ]] && [[ $count -lt 6 ]]
  do
    if [[ $(echo $keys | wc -w | awk '{print $1}') -ne 3 ]]
    then
      keys="$(curl -s -XGET http://consul:8500/v1/kv/elasticsearch/cluster/nodes?recurse | jq -r '.[] | .Key')"
    fi

    sleep 10
    ((count++))
  done

  ## quit if count > 5
  [[ $count -gt 5 ]] && echo "  cluster bootstrap timeout. only $(echo $keys | wc -w | awk '{print $1}') nodes registered" >&2 && exit 1

  for key in $keys
  do
    if [[ -z "$hosts" ]]
    then
      hosts=$(curl -s -XGET http://consul:8500/v1/kv/${key}?raw)
    else
      hosts="${hosts},$(curl -s -XGET http://consul:8500/v1/kv/${key}?raw)"
    fi
  done

  echo $hosts
}

HOST="$(cat /docker_hostname)"
IP="$(dig ${HOST}.node.consul. +short)"
SESSION_ID="$(create_consul_session)"

add_consul_key

hosts=$(wait_for_nodes)

/usr/share/elasticsearch/bin/elasticsearch -Des.default.path.conf=/elasticsearch/etc/ --node.name=$(hostname) --discovery.zen.ping.unicast.hosts=$hosts --network.publish_host=$IP
