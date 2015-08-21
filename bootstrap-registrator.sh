#! /bin/bash

for node in $(docker-machine ls -q | grep swarm);
do
  eval $(docker-machine env $node)

  docker rm -f registrator
  docker run --net=host --name registrator -d labrute974/consul -join $(docker-machine ip mgmt) -advertise $(docker-machine ip $node)
done
