# VERSION 1.7.1.3-5
# AUTHOR: Matthieu "Puckel_" Roisil
# DESCRIPTION: Basic Airflow container
# BUILD: docker build --rm -t puckel/docker-airflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM debian:jessie
MAINTAINER Puckel_

RUN mkdir -p /opt/oracle/instantclient_12_1 \
   && mkdir -p /usr/local/airflow \
   && ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime \
   && apt-get update && apt-get install -y apt-utils build-essential unzip python-dev libaio-dev
   
ADD oracle/instantclient-basic-linux.x64-12.1.0.2.0.zip /opt/oracle/
ADD oracle/instantclient-sdk-linux.x64-12.1.0.2.0.zip /opt/oracle/

RUN cd /opt/oracle && unzip instantclient-basic-linux.x64-12.1.0.2.0.zip \
   && unzip instantclient-sdk-linux.x64-12.1.0.2.0.zip \
   && cd /opt/oracle/instantclient_12_1 \
   && ln -s libclntsh.so.12.1 libclntsh.so \
   && ln -s libocci.so.12.1 libocci.so

# Never prompts the user for choices on installation/configuration of packages
ENV DEBIAN_FRONTEND noninteractive
ENV TERM linux

# Oracle
ENV ORACLE_HOME /opt/oracle/instantclient_12_1
ENV LD_LIBRARY_PATH $ORACLE_HOME:$LD_LIBRARY_PATH
ENV PATH=$ORACLE_HOME:$PATH

# Airflow
ARG AIRFLOW_VERSION=1.7.1.3
ENV AIRFLOW_HOME /usr/local/airflow


# Define en_US.
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_MESSAGES en_US.UTF-8
ENV LC_ALL  en_US.UTF-8

RUN echo "/opt/oracle/instantclient_12_1" > /etc/ld.so.conf.d/oracle.conf && ldconfig 

RUN pip install requests && pip install retrying

RUN set -ex \
    && buildDeps=' \
        python-dev \
        libkrb5-dev \
        libsasl2-dev \
        libssl-dev \
        libffi-dev \
        build-essential \
        libblas-dev \
        liblapack-dev \
    ' \
    && echo "deb http://http.debian.net/debian jessie-backports main" >/etc/apt/sources.list.d/backports.list \
    && apt-get update -yqq \
    && apt-get install -yqq --no-install-recommends \
        $buildDeps \
        python-pip \
        apt-utils \
        curl \
        netcat \
        locales \
    && apt-get install -yqq -t jessie-backports python-requests libpq-dev \
    && sed -i 's/^# en_US.UTF-8 UTF-8$/en_US.UTF-8 UTF-8/g' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && useradd -ms /bin/bash -d ${AIRFLOW_HOME} airflow \
    && pip install Cython \
    && pip install pytz==2015.7 \
    && pip install cryptography \
    && pip install pyOpenSSL \
    && pip install ndg-httpsclient \
    && pip install pyasn1 \
    && pip install psycopg2 \
    && pip install pandas==0.18.1 \
    && pip install celery==3.1.23 \
    && pip install airflow[celery,postgres,hive,hdfs,jdbc]==$AIRFLOW_VERSION \
    && apt-get remove --purge -yqq $buildDeps libpq-dev \
    && apt-get clean \
    && rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /var/tmp/* \
        /usr/share/man \
        /usr/share/doc \
        /usr/share/doc-base

COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_HOME}
ENTRYPOINT ["/entrypoint.sh"]
