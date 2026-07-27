#FROM centos:centos7
FROM dockerhub.suntekcorps.com:8443/suntek/almalinux-php8-swoole6.x:2.0.1
MAINTAINER sunny5156 <sunny5156@qq.com>


ADD ./src/rpm /vue-msf/src
ADD ./src/rabbitmq /vue-msf/rabbitmq

RUN cd /vue-msf/src/ \
    && yum install -y erlang-26.2.5-1.el8.x86_64.rpm \
    rabbitmq-server-3.13.7-1.el8.noarch.rpm \
    && mkdir -p /vue-msf/rabbitmq


ADD ./src/config/supervisor/rabbitmq.conf /vue-msf/supervisor/conf.d/
ADD ./src/config/rabbitmq /vue-msf/rabbitmq

# rabbitmq-env.conf carries the Erlang allocator tuning
# (RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS, mapped by the upstream 3.13.7
#  rabbitmq-env script); rabbitmq.config sets loopback_users to [] so the
#  guest account can log in from remote hosts. The 3.8-era custom
#  rabbitmq-server override is no longer copied -- the stock 3.13.7 script
#  already applies SERVER_ADDITIONAL_ERL_ARGS from rabbitmq-env.conf.
RUN cd /vue-msf/rabbitmq \
    && ls -al \
    && cp -i rabbitmq-env.conf /etc/rabbitmq/ \
    && cp -i rabbitmq.config /etc/rabbitmq/ \
    && mkdir -p /vue-msf/bin \
    && cp /vue-msf/rabbitmq/init.sh /vue-msf/bin


RUN /usr/sbin/rabbitmq-plugins enable rabbitmq_management
# && /usr/sbin/rabbitmqctl add_user super super
# && /usr/sbin/rabbitmqctl set_user_tags  super administrator

##RUN echo -e "\nsource /vue-msf/rabbitmq/add-super.sh" >> /run.sh
