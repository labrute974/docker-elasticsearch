FROM centos
MAINTAINER Karel Malbroukou <karel.malbroukou@gmail.com>

ADD config/elastic.repo /etc/yum.repos.d/
RUN rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
RUN yum -y install java-1.8.0-openjdk elasticsearch bind-utils

RUN mkdir -p /elasticsearch/{data,logs,work,plugins,etc} /etc/elasticsearch
ADD config/elasticsearch.yml /elasticsearch/etc/
ADD config/consul_session.json /elasticsearch/etc/
RUN cp /etc/elasticsearch/logging.yml /elasticsearch/etc/logging.yml

RUN chown -R elasticsearch: /elasticsearch
RUN usermod -d /elasticsearch elasticsearch

ADD http://stedolan.github.io/jq/download/linux64/jq /usr/local/bin/jq
RUN chmod +x /usr/local/bin/jq

ADD bin/ /usr/local/bin/

EXPOSE 9200

CMD [ "/usr/local/bin/start-elasticsearch.sh" ]
