# base
FROM centos:7 as base
MAINTAINER Dieudonne lx <lx.simon@yahoo.com>
RUN yum -y update \
    && yum install -y bzip2 sudo unzip \
    && yum clean all -y \
    && rm -rf /var/cache/yum
# install jdk8
FROM base as jdk
MAINTAINER Dieudonne lx <lx.simon@yahoo.com>

RUN curl -o /opt/jdk8.tar.gz http://192.168.8.101:8000/jdk-8u231-linux-x64.tar.gz \
    && tar -xzf /opt/jdk8.tar.gz -C /opt \
    && rm -f /opt/jdk8.tar.gz \
    && mv /opt/jdk1.8.0* /usr/local/jdk1.8.0 \
    && tar -C /usr/local -czf /opt/jdk8.tar.gz jdk1.8.0

# install python
FROM base as python
MAINTAINER Dieudonne lx <lx.simon@yahoo.com>

RUN curl -o conda.sh https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
# RUN curl -o conda.sh http://192.168.8.100:8000/Anaconda3-2019.03-Linux-x86_64.sh && \
    bash conda.sh -b -f -p /usr/local/python3 && \
    rm -f conda.sh
ENV PATH=/usr/local/python3/bin:$PATH
RUN conda update -y --all \
    && conda install -y requests \
    && conda clean --all -y \
    && rm -rf ~/.cache/pip/*

# install hadoop
FROM base as hadoop
ENV HADOOP_VERSION=2.7.2
# RUN curl -L https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz | tar -xzf - -C /opt \
RUN curl -L http://192.168.8.101:8000/hadoop-${HADOOP_VERSION}.tar.gz | tar -xzf - -C /opt \
    && mv /opt/hadoop-* /usr/local/hadoop \
    && chmod -x /usr/local/hadoop/bin/*.cmd /usr/local/hadoop/sbin/*.cmd

# install spark
FROM base as spark
ENV SPARK_VERSION=2.4.4 \
    SPARK_HADOOP_VERSION=2.7 
# RUN curl -L https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${SPARK_HADOOP_VERSION}.tgz | tar -xzf - -C /opt \
RUN curl -L http://192.168.8.101:8000/spark-2.4.4-bin-hadoop2.7.tgz | tar -xzf - -C /opt \
    && mv /opt/spark-* /usr/local/spark \
    && chmod -x /usr/local/spark/bin/*.cmd
COPY conf/spark/* /usr/local/spark/conf/

FROM centos:7 as prod
ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm \
    SLUGIFY_USES_TEXT_UNIDECODE=yes \
    USER_PATH=/usr/local
ENV JAVA_HOME=${USER_PATH}/jdk1.8.0 \
    HADOOP_HOME=${USER_PATH}/hadoop \
    SPARK_HOME=${USER_PATH}/spark
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop \
    PATH=${USER_PATH}/python3/bin:$JAVA_HOME/bin:${HADOOP_HOME}/bin:$SPARK_HOME/bin:$PATH
RUN yum -y update \
    && yum install -y which openssh openssh-clients openssh-server vim sudo \
    && yum clean all -y \
    && rm -rf /var/cache/yum
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime
RUN localedef -i en_US -f UTF-8 en_US.UTF-8
RUN sed -i -e '/Defaults    requiretty/{ s/.*/# Defaults    requiretty/ }' /etc/sudoers
COPY --from=jdk /usr/local/jdk1.8.0 ${JAVA_HOME}
COPY --from=jdk /opt/jdk8.tar.gz /opt/
COPY --from=python ${USER_PATH}/python3 ${USER_PATH}/python3
COPY --from=hadoop ${HADOOP_HOME} ${HADOOP_HOME}
COPY --from=spark ${SPARK_HOME} ${SPARK_HOME}
RUN useradd elasticsearch \
    && useradd gdata \
    && useradd baitu
WORKDIR /opt/baitu
VOLUME [ "${HADOOP_CONF_DIR}", "/opt/baitu", "/usr/lib/transwarp/scripts", "/etc/transwarp/conf" ]
EXPOSE 19090
CMD ["/bin/bash"]

