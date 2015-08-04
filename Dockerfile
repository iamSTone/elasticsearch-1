# from https://github.com/dockerfile/java/blob/master/oracle-java8/Dockerfile
# from https://github.com/nacyot/elasticsearch
# The MIT License (MIT)
# Copyright (c) Dockerfile Project
#
FROM ubuntu:14.04

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y byobu curl git htop man unzip vim wget && \
  rm -rf /var/lib/apt/lists/*

# Install Java.
RUN \
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer

# Define working directory.
WORKDIR /data

# Define commonly used JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
ENV ES_PKG_NAME elasticsearch-1.7.0

RUN \
  apt-get update &&\
  apt-get install -y automake perl build-essential

# Install Elasticsearch.
RUN \
  cd / && \
  wget https://download.elastic.co/elasticsearch/elasticsearch/$ES_PKG_NAME.tar.gz && \
  tar xvzf $ES_PKG_NAME.tar.gz && \
  rm -f $ES_PKG_NAME.tar.gz && \
  mv /$ES_PKG_NAME /elasticsearch

# Install mecab-ko
RUN \
  cd /opt &&\
  wget https://bitbucket.org/eunjeon/mecab-ko/downloads/mecab-0.996-ko-0.9.2.tar.gz &&\
  tar xvf mecab-0.996-ko-0.9.2.tar.gz &&\
  cd /opt/mecab-0.996-ko-0.9.2 &&\
  ./configure &&\
  make &&\
  make check &&\
  make install &&\
  ldconfig

RUN \
  cd /opt &&\
  wget https://bitbucket.org/eunjeon/mecab-ko-dic/downloads/mecab-ko-dic-2.0.1-20150707.tar.gz &&\
  tar xvf mecab-ko-dic-2.0.1-20150707.tar.gz &&\
  cd /opt/mecab-ko-dic-2.0.1-20150707 &&\
  ./autogen.sh &&\
  ./configure &&\
  make &&\
  make install

# Install user dic
ADD https://raw.githubusercontent.com/n42corp/search-ko-dic/master/servicecustom.csv /opt/mecab-ko-dic-2.0.1-20150707/user-dic/servicecustom.csv
RUN cd /opt/mecab-ko-dic-2.0.1-20150707 &&\
  tools/add-userdic.sh &&\
  make install

# Add synonym
ADD https://raw.githubusercontent.com/n42corp/search-ko-dic/master/synonym.txt /elasticsearch/config/synonym.txt

ENV JAVA_TOOL_OPTIONS -Dfile.encoding=UTF8

RUN \
  cd /opt &&\
  wget https://mecab.googlecode.com/files/mecab-java-0.996.tar.gz &&\
  tar xvf mecab-java-0.996.tar.gz &&\
  cd /opt/mecab-java-0.996 &&\
  sed -i 's|/usr/lib/jvm/java-6-openjdk/include|/usr/lib/jvm/java-8-oracle/include|' Makefile &&\
  make &&\
  cp libMeCab.so /usr/local/lib

# Define mountable directories.
VOLUME ["/data"]

# Mount elasticsearch.yml config
COPY config/elasticsearch.yml /elasticsearch/config/elasticsearch.yml

# Install mecab-ko-analyzer(elasticsearch plugin)
RUN /elasticsearch/bin/plugin --install analysis-mecab-ko-0.17.0 --url https://bitbucket.org/eunjeon/mecab-ko-lucene-analyzer/downloads/elasticsearch-analysis-mecab-ko-0.17.0.zip

# Install elasticsearch plugin
RUN /elasticsearch/bin/plugin --install mobz/elasticsearch-head
RUN /elasticsearch/bin/plugin --install lmenezes/elasticsearch-kopf/v1.5.6
RUN /elasticsearch/bin/plugin --install polyfractal/elasticsearch-inquisitor

# Define default command.
ENTRYPOINT ["/elasticsearch/bin/elasticsearch", "-Djava.library.path=/usr/local/lib"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300
