FROM centos:7
MAINTAINER Dieudonne lx <lx.simon@yahoo.com>

ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    HADOOP_VERSION=2.7.2 \
    SPARK_VERSION=2.2.1 \
    SPARK_HADOOP_VERSION=2.7
ENV JAVA_HOME="/opt/distribute/jdk1.8.0" \
    HADOOP_HOME="/opt/distribute/hadoop-${HADOOP_VERSION}" \
    HADOOP_CONF_DIR="/opt/distribute/hadoop-${HADOOP_VERSION}/etc/hadoop" \
    SPARK_HOME="/opt/distribute/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}"
ENV PATH="/opt/distribute/python3/bin:$JAVA_HOME/bin:$SPARK_HOME/bin:$PATH"
RUN yum -y update \
    && yum install -y which openssh openssh-clients openssh-server bzip2 vim sudo unzip \
    && yum clean all -y \
    && rm -rf /var/cache/yum
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN sed -i -e '/Defaults    requiretty/{ s/.*/# Defaults    requiretty/ }' /etc/sudoers
RUN mkdir /opt/distribute
# install jdk
RUN curl -o /opt/distribute/jdk8.tar.gz -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/jdk-8u181-linux-x64.tar.gz \
    && tar -xzf /opt/distribute/jdk8.tar.gz -C /opt/distribute \
    && mv /opt/distribute/jdk1.8.0* /opt/distribute/jdk1.8.0
# install miniconda3
RUN curl -o conda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash conda.sh -b -f -p /opt/distribute/python3 && \
    rm -f conda.sh
RUN conda update -y --all \
    && conda install -y requests \
    && conda clean --all -y
#    && rm -rf ~/.cache/pip/*
# install hadoop
RUN curl -L https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar -xzf - -C /opt/distribute
# install spark
RUN curl -L https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz | tar -xzf - -C /opt/distribute
COPY conf/spark/* /opt/distribute/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}/conf/
RUN useradd elasticsearch \
    && useradd gdata \
    && useradd baitu
WORKDIR /opt/baitu
VOLUME [ "${HADOOP_CONF_DIR}", "/opt/baitu", "/usr/lib/transwarp/scripts", "/etc/transwarp/conf" ]
EXPOSE 19090
CMD ["/bin/bash"]
