#FROM centos:centos7
FROM dockerhub.suntekcorps.com:8443/suntek/almalinux-php8-swoole6.x:2.0.1 AS erlang-builder

# Erlang 27.3.4 from source. RabbitMQ 4.3.x requires Erlang 27 (Erlang 26 is
# "no longer supported" per the RabbitMQ/Erlang matrix and the broker refuses
# to start on it); the rabbitmq zero-dependency Erlang RPM repo (packagecloud
# rabbitmq/erlang) tops out at 26.2.5.4 with no OTP 27, and the 4.3.4 GitHub
# release ships no Erlang RPM either -- so build 27.3.4 from source into
# /usr/lib64/erlang.
COPY ./src/rpm/otp_src_27.3.4.tar.gz /tmp/erlang.tgz
RUN yum install -y gcc gcc-c++ make m4 perl ncurses-devel openssl-devel zlib-devel \
    && mkdir -p /tmp/erlang-src \
    && tar xzf /tmp/erlang.tgz -C /tmp/erlang-src --strip-components=1 \
    && cd /tmp/erlang-src \
    && ./configure --prefix=/usr/lib64/erlang --without-javac \
    && make -j"$(nproc)" \
    && make install


FROM dockerhub.suntekcorps.com:8443/suntek/almalinux-php8-swoole6.x:2.0.1
MAINTAINER sunny5156 <sunny5156@qq.com>
ENV PATH=/usr/lib64/erlang/bin:$PATH

ADD ./src/rpm/rabbitmq-server-4.3.4-1.el8.noarch.rpm /vue-msf/src/
ADD ./src/rabbitmq /vue-msf/rabbitmq
# Copy the source-built Erlang 27.3.4 in (no build toolchain in the final image).
COPY --from=erlang-builder /usr/lib64/erlang /usr/lib64/erlang

# Install RabbitMQ 4.3.4 (el8 RPM). Erlang is the source build above (not a
# yum package), so install the RPM with --nodeps; pull its other runtime deps
# (socat, logrotate) from the el8 repos first.
RUN cd /vue-msf/src/ \
    && yum install -y socat logrotate \
    && rpm -ivh --nodeps rabbitmq-server-4.3.4-1.el8.noarch.rpm \
    && rm -f rabbitmq-server-4.3.4-1.el8.noarch.rpm \
    && mkdir -p /vue-msf/rabbitmq


ADD ./src/config/supervisor/rabbitmq.conf /vue-msf/supervisor/conf.d/
ADD ./src/config/rabbitmq /vue-msf/rabbitmq

# rabbitmq-env.conf: Erlang allocator tuning (RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS,
# still mapped by the 4.3.4 rabbitmq-env script). rabbitmq.conf: HOCON config
# (4.x dropped the classic rabbitmq.config erlang-term format) setting
# loopback_users.guest=false so guest can log in from remote hosts.
RUN cd /vue-msf/rabbitmq \
    && ls -al \
    && cp -i rabbitmq-env.conf /etc/rabbitmq/ \
    && cp -i rabbitmq.conf /etc/rabbitmq/ \
    && mkdir -p /vue-msf/bin \
    && cp /vue-msf/rabbitmq/init.sh /vue-msf/bin


RUN /usr/sbin/rabbitmq-plugins enable rabbitmq_management
# && /usr/sbin/rabbitmqctl add_user super super
# && /usr/sbin/rabbitmqctl set_user_tags  super administrator

##RUN echo -e "\nsource /vue-msf/rabbitmq/add-super.sh" >> /run.sh
