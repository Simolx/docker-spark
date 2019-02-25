FROM centos:7
MAINTAINER Dieudonne lx <lx.simon@yahoo.com>

ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm \
    SLUGIFY_USES_TEXT_UNIDECODE=yes \
    HADOOP_VERSION=2.7.2 \
    SPARK_VERSION=2.3.2 \
    SPARK_HADOOP_VERSION=2.7 \
    USER_PATH=/usr/local
ENV JAVA_HOME=${USER_PATH}/jdk1.8.0 \
    HADOOP_HOME=${USER_PATH}/hadoop \
    SPARK_HOME=${USER_PATH}/spark
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    PATH=${USER_PATH}/python3/bin:$JAVA_HOME/bin:${HADOOP_HOME}/bin:$SPARK_HOME/bin:$PATH
RUN yum -y update \
    && yum install -y which openssh openssh-clients openssh-server bzip2 vim sudo unzip \
    && yum clean all -y \
    && rm -rf /var/cache/yum
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN sed -i -e '/Defaults    requiretty/{ s/.*/# Defaults    requiretty/ }' /etc/sudoers
# install jdk
RUN curl -o /opt/jdk8.tar.gz -v -j -k -L -H "Cookie: oraclelicense=accept-securebackup-cookie" \
https://download.oracle.com/otn-pub/java/jdk/8u201-b09/42970487e3af4f5aa5bca3f542482c60/jdk-8u201-linux-x64.tar.gz \
    && tar -xzf /opt/jdk8.tar.gz -C /opt \
    && rm -f /opt/jdk8.tar.gz \
    && mv /opt/jdk1.8.0* ${JAVA_HOME} \
    && tar -C ${USER_PATH} -czf /opt/jdk8.tar.gz jdk1.8.0
# install miniconda3
RUN curl -o conda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash conda.sh -b -f -p /usr/local/python3 && \
    rm -f conda.sh
RUN conda update -y --all \
    && conda install -y python=3.6 requests \
    && conda clean --all -y
#    && rm -rf ~/.cache/pip/*
# install hadoop
RUN curl -L https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar -xzf - -C /opt \
    && mv /opt/hadoop-* ${HADOOP_HOME} \
    && chmod -x ${HADOOP_HOME}/bin/*.cmd ${HADOOP_HOME}/sbin/*.cmd
# install spark
RUN curl -L https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz | tar -xzf - -C /opt \
    && mv /opt/spark-* ${SPARK_HOME} \
    && chmod -x ${SPARK_HOME}/bin/*.cmd
COPY conf/spark/* ${SPARK_HOME}/conf/
RUN useradd elasticsearch \
    && useradd gdata \
    && useradd baitu
WORKDIR /opt/baitu
VOLUME [ "${HADOOP_CONF_DIR}", "/opt/baitu", "/usr/lib/transwarp/scripts", "/etc/transwarp/conf" ]
EXPOSE 19090
CMD ["/bin/bash"]
