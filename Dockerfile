FROM centos:7
MAINTAINER lx,simolx@163.com

ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    ANACONDA_VERSION=5.0.1 \
    HADOOP_VERSION=2.7.2 \
    SPARK_VERSION=2.2.1 \
    SPARK_HADOOP_VERSION=2.7 \
    JAVA_HOME="/opt/distribute/jdk1.8.0_151" \
    HADOOP_HOME="/opt/distribute/hadoop-${HADOOP_VERSION}"
    HADOOP_CONF_DIR="${HADOOP_HOME}/etc/hadoop" \
    SPARK_HOME="/opt/distribute/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}"
    PATH="/opt/distribute/anaconda3/bin:$JAVA_HOME/bin:$PATH"

RUN yum -y update && \
    yum install -y which openssh openssh-clients openssh-server bzip2 vim sudo unzip crontabs && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN /bin/cp -f /usr/share/zoneinfo/$TZ /etc/localtime
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN sed -i -e '/Defaults    requiretty/{ s/.*/# Defaults    requiretty/ }' /etc/sudoers

RUN mkdir /opt/distribute

# install jdk
RUN curl -O -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.tar.gz \
    && tar -xzf jdk-8u151-linux-x64.tar.gz -C /opt/distribute \
    && mv jdk-8u151-linux-x64.tar.gz /opt/distribute

# install anaconda3
RUN curl -O https://repo.continuum.io/archive/Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh && \
    bash Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh -b -f -p /opt/distribute/anaconda3 && \
    rm -f Anaconda3-${ANACONDA_VERSION}-Linux-x86_64.sh
RUN conda update -y conda \
    && conda update -y --all \
    && pip install --upgrade pip setuptools \
    && pip install kafka-python jieba \
    && rm -rf ~/.cache/pip/*

# add hadoop configuration
RUN curl -O -L https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -C /opt/distribute -xzf hadoop-${HADOOP_VERSION}.tar.gz hadoop-${HADOOP_VERSION}/etc \
    && rm -rf hadoop-${HADOOP_VERSION}.tar.gz 

# install spark
RUN curl -O -L https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz -C /opt/distribute \
    && rm -f spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz
COPY conf/spark/* /opt/distribute/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}/conf

RUN useradd elasticsearch \
    && useradd gdata
WORKDIR /opt/baitu
VOLUME [ "${HADOOP_CONF_DIR}", "/opt/baitu" ]
EXPOSE 19090
CMD ["/bin/bash"]
