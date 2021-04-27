#FROM centos:centos7
FROM hub.docker.thinkchanges.cn/suntek/vue-msf-docker:1.2.9
MAINTAINER sunny5156 <sunny5156@qq.com>


ADD ./src/rpm /vue-msf/src

RUN cd /vue-msf/src/ \
    && yum install -y erlang-23.2.5-1.el7.x86_64.rpm \
    rabbitmq-server-3.8.12-1.el7.noarch.rpm \
    && mkdir -p /vue-msf/rabbitmq


ADD ./src/config/supervisor/rabbitmq.conf /vue-msf/supervisor/conf.d/
ADD ./src/config/rabbitmq /vue-msf/rabbitmq

RUN cd /vue-msf/rabbitmq \
    && ls -al \
    && cp -i rabbitmq-env.conf /etc/rabbitmq/ \
    && cp -i rabbitmq-server /usr/lib/rabbitmq/lib/rabbitmq_server-3.8.12/sbin



#ENTRYPOINT ["./dolphindb"]