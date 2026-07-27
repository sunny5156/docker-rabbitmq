# docker-rabbitmq

基于 AlmaLinux 8（el8）的 RabbitMQ 容器镜像，由 supervisor 托管启动。

## 版本

| 组件 | 版本 |
| --- | --- |
| 基础镜像 | `dockerhub.suntekcorps.com:8443/suntek/almalinux-php8-swoole6.x:2.0.1` |
| Erlang/OTP | 27.3.4（源码编译） |
| RabbitMQ | 4.3.4（el8 RPM） |

RabbitMQ 4.3 要求 Erlang 27（Erlang 26 已不再支持、会被拒绝启动），而 rabbitmq 官方零依赖 Erlang RPM 仓库（packagecloud `rabbitmq/erlang`）最高只到 26.2.5.4、没有 OTP 27，4.3.4 的 GitHub release 也不带 Erlang RPM。因此本镜像用**多阶段构建**：第一阶段从 `otp_src_27.3.4.tar.gz` 源码编译 Erlang 27.3.4 到 `/usr/lib64/erlang`，第二阶段把编译产物 `COPY` 进最终镜像（不含 gcc 等构建依赖），再装 RabbitMQ 4.3.4 的 el8 RPM。

> 构建会比纯 RPM 安装慢（Erlang 编译约 5–10 分钟），但最终镜像不含构建工具链。

## 构建

```bash
docker build -t docker-rabbitmq:4.3.4 .
```

## 运行

```bash
docker run -d --name rabbitmq \
  -p 5672:5672 \
  -p 15672:15672 \
  docker-rabbitmq:4.3.4
```

- `5672` — AMQP
- `15672` — 管理界面（management 插件已启用）

默认账号 `guest` / `guest`。`rabbitmq.conf` 中设置 `loopback_users.guest = false`，允许从远端登录 guest（仅适用于开发/内网环境，生产环境请改为创建独立账号）。

## 配置文件

| 文件 | 作用 |
| --- | --- |
| `src/config/rabbitmq/rabbitmq-env.conf` | Erlang 内存分配器参数（`SERVER_ADDITIONAL_ERL_ARGS`），由 4.3.4 的 `rabbitmq-env` 脚本映射为 `RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS` |
| `src/config/rabbitmq/rabbitmq.conf` | HOCON 配置（4.x 不再支持经典 `rabbitmq.config` 格式）；`loopback_users.guest = false` |
| `src/config/supervisor/rabbitmq.conf` | supervisor 程序配置，启动 `src/rabbitmq/rabbitmq.sh` |
| `src/rabbitmq/rabbitmq.sh` | 启动 `rabbitmq-server`，退出时 `rabbitmqctl stop` |
| `src/rabbitmq/add-super.sh` | 创建 `super` 管理员账号（按需在 `run.sh` 中 source） |

> 注：4.x 较 3.x 的破坏性变更——经典 `rabbitmq.config`（erlang term）格式被移除，改用 HOCON `rabbitmq.conf`；经典队列镜像（classic mirroring）移除，仅保留 quorum/stream；元数据存储默认切换为 Khepri。本镜像为全新容器部署（无 3.x 数据迁移）。从已有 3.x 数据目录原地升级需先做 Khepri 迁移，不在本镜像范围内。

> 注：旧版（3.8.12）会复制一份定制的 `rabbitmq-server` 启动脚本来覆盖上游脚本。3.13.7 起上游 `rabbitmq-server` 脚本已直接应用 `rabbitmq-env.conf` 里的 `SERVER_ADDITIONAL_ERL_ARGS`，定制覆盖不再需要。`src/config/rabbitmq/rabbitmq-server` 为旧版残留，可按需删除。
