# docker-rabbitmq

基于 AlmaLinux 8（el8）的 RabbitMQ 容器镜像，由 supervisor 托管启动。

## 版本

| 组件 | 版本 |
| --- | --- |
| 基础镜像 | `dockerhub.suntekcorps.com:8443/suntek/almalinux-php8-swoole6.x:2.0.1` |
| Erlang/OTP | 26.2.5（el8） |
| RabbitMQ | 3.13.7（el8） |

RabbitMQ 3.13 不再提供 el7 包（CentOS 7 已 EOL），也不兼容 Erlang 23，因此本镜像一并升级到 Erlang 26.2.5 + RabbitMQ 3.13.7 的 el8 RPM。

## 构建

```bash
docker build -t docker-rabbitmq:3.13.7 .
```

## 运行

```bash
docker run -d --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  docker-rabbitmq:3.13.7
```

- `5672` — AMQP
- `15672` — 管理界面（management 插件已启用）

默认账号 `guest` / `guest`。`rabbitmq.config` 中设置了 `loopback_users = []`，允许从远端登录 guest（仅适用于开发/内网环境，生产环境请改为创建独立账号）。

## 配置文件

| 文件 | 作用 |
| --- | --- |
| `src/config/rabbitmq/rabbitmq-env.conf` | Erlang 内存分配器参数（`SERVER_ADDITIONAL_ERL_ARGS`），由 3.13.7 的 `rabbitmq-env` 脚本映射为 `RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` |
| `src/config/rabbitmq/rabbitmq.config` | 经典配置，`loopback_users` 设为 `[]` |
| `src/config/supervisor/rabbitmq.conf` | supervisor 程序配置，启动 `src/rabbitmq/rabbitmq.sh` |
| `src/rabbitmq/rabbitmq.sh` | 启动 `rabbitmq-server`，退出时 `rabbitmqctl stop` |
| `src/rabbitmq/add-super.sh` | 创建 `super` 管理员账号（按需在 `run.sh` 中 source） |

> 注：旧版（3.8.12）会复制一份定制的 `rabbitmq-server` 启动脚本来覆盖上游脚本。3.13.7 的上游 `rabbitmq-server` 脚本已经直接应用 `rabbitmq-env.conf` 里的 `SERVER_ADDITIONAL_ERL_ARGS`，定制覆盖已不再需要，故不再复制。`src/config/rabbitmq/rabbitmq-server` 为旧版残留，可按需删除。
