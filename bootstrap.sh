#! /bin/bash

for node in $(docker-machine ls -q | grep swarm)
do
  eval "$(docker-machine env $node)"
  docker build -t labrute974/elasticsearch:latest .
done
