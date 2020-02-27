FROM ubuntu:16.04
###########################################################################
# ARG app Version
###########################################################################
ARG JENKINS_SLAVE_VER=3.29
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG AGENT_WORKDIR=/home/${user}/agent
ARG KUBECTL=v1.10.12
ARG HELM=v2.11.0
ARG TERRAFORM=0.12.3
ARG DOCKER_VERSION=18.09.0
ARG MAVEN_VERSION=3.6.1

###########################################################################
# ENV
###########################################################################
ENV HOME /home/${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
ENV JAVA_OPTS -Dsun.jnu.encoding=UTF-8 -Dfile.encoding=UTF-8

###########################################################################
# COPY
###########################################################################
COPY jenkins-slave /usr/local/bin/jenkins-slave
COPY tools/* /

###########################################################################
# LABEL
###########################################################################
LABEL Description="This is a base image, which provides the Jenkins agent executable (slave.jar)" Vendor="Jenkins project" Version="${JENKINS_SLAVE_VER}"



###########################################################################
# RUN
###########################################################################
#RUN echo 'deb http://deb.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/stretch-backports.list

## dash > bash
RUN echo "######### dash > bash ##########" \
  && mv /bin/sh /bin/sh.old && ln -s bash /bin/sh

## apt update && apt-get clean
RUN echo "######### apt update ##########" \
  && apt-get update && apt-get install -y default-jre default-jdk sudo vim wget netcat git curl unzip locales unzip rsync python python-pip netcat git \
  && rm -rf /var/lib/apt/lists/* && apt-get clean

## add root bashrc
RUN echo "######### add root bashrc ##########" \
  && locale-gen zh_TW.UTF-8 && echo 'export LANGUAGE="zh_TW.UTF-8"' >> /root/.bashrc \
  && echo 'export LANG="zh_TW.UTF-8"' >> /root/.bashrc \
  && echo 'export LC_ALL="zh_TW.UTF-8"' >> /root/.bashrc && update-locale LANG=zh_TW.UTF-8

## ssh_config
RUN echo "######### ssh_config ##########" \
  && echo "Host *" >> /etc/ssh/ssh_config \
  && echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
  && echo "    UserKnownHostsFile /dev/null" >> /etc/ssh/ssh_config

## user add jenkins
RUN echo "######### user add jenkins ##########" \
  && mkdir -p ${HOME} \
  && groupadd -g ${gid} ${group} \
  && useradd  -d ${HOME} -u ${uid} -g ${gid}  -G sudo ${user} \
  && chown -R ${uid}:${gid} ${HOME} \
  && echo "jenkins ALL=NOPASSWD: ALL" >> /etc/sudoers

## install slave.jar
RUN echo "######### install slave.jar ##########" \
  && mkdir /usr/share/jenkins && chmod 755 /usr/share/jenkins \
  && curl --create-dirs -fsSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${JENKINS_SLAVE_VER}/remoting-${JENKINS_SLAVE_VER}.jar \
  && chmod 644 /usr/share/jenkins/slave.jar \
  && mkdir -p /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR} \
  && chmod +x /usr/local/bin/jenkins-slave \
  && chown -R ${user} /home/${user}

## install ansible
RUN echo "######### install ansible ##########" \
  && apt-get update && apt-get install software-properties-common -y \
  && apt-add-repository ppa:ansible/ansible \
  && apt-get install ansible -y \
  && rm -rf /var/lib/apt/lists/* && apt-get clean

## install aws cli
RUN echo "######### install aws cli ##########" \
  && apt-get update && apt install awscli groff -y \
  && rm -rf /var/lib/apt/lists/* && apt-get clean


RUN echo "######### kubernetes-client ##########" \
  && tar -xzvf kubernetes-client-linux-amd64.tar.gz \
  && mv kubernetes/client/bin/kubectl  /usr/bin/ \
  && rm -f kubernetes-client-linux-amd64.tar.gz \
  && rm -rf kubernetes \
  && echo "######### helm ##########" \
  && tar -zxf helm-${HELM}-linux-amd64.tar.gz \
  && mv linux-amd64/helm linux-amd64/tiller /usr/bin/ \
  && rm -rf linux-amd64 \
  && rm -f helm-${HELM}-linux-amd64.tar.gz \
  && echo "######### terraform ##########" \
  && unzip terraform_${TERRAFORM}_linux_amd64.zip \
  && mv terraform /usr/bin/ \
  && rm -f terraform_${TERRAFORM}_linux_amd64.zip \
  && echo "######### maven ##########" \
  && tar -zxvf apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && rm -f apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && mv apache-maven-${MAVEN_VERSION} /usr/local

RUN echo "######### docker ##########" \
  && apt -y update \
  && apt -y install apt-transport-https ca-certificates curl software-properties-common \
  && curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add - \
  && apt-key fingerprint 0EBFCD88 \
  && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  && apt-get -y update \
  && apt -y install docker-ce \
  && apt -y install docker-compose \
  && usermod -aG docker "${user}" \
  && apt-get clean

###########################################################################
# USER
###########################################################################
USER ${user}

###########################################################################
# WORKDIR
###########################################################################
WORKDIR /home/${user}

###########################################################################
# VOLUME
###########################################################################
VOLUME ["/home/${user}/.jenkins","${AGENT_WORKDIR}"]

###########################################################################
# ENTRYPOINT
###########################################################################
ENTRYPOINT ["jenkins-slave"]
