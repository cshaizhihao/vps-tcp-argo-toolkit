# VPS TCP Tune + Argo VMess Toolkit

专用一键脚本仓库：

1. **全自动 TCP 优化**：保留原 TCP 调优脚本菜单 `66` 能力，即 XanMod + BBR v3 + 网络调优。
2. **Argo VMess + WebSocket**：从 ArgoX 中只启用 `VMess + WS` 协议，并生成节点/订阅 URL。

## 当前主入口

```text
scripts/vps-argo-vmess-oneclick.sh
```

### 在线执行

```bash
curl -fsSL https://raw.githubusercontent.com/cshaizhihao/vps-tcp-argo-toolkit/main/scripts/vps-argo-vmess-oneclick.sh -o /tmp/vps-argo-vmess-oneclick.sh && bash /tmp/vps-argo-vmess-oneclick.sh --all
```

### 推荐流程

首次运行：

```bash
curl -fsSL https://raw.githubusercontent.com/cshaizhihao/vps-tcp-argo-toolkit/main/scripts/vps-argo-vmess-oneclick.sh -o /tmp/speed && bash /tmp/speed --all
```

如果 TCP 阶段安装了 XanMod / BBR v3 内核，脚本会提示重启。重启后执行：

```bash
speed --continue
```

`speed --continue` 会继续完成：

1. TCP 网络调优第二阶段
2. Argo VMess + WS 安装
3. 节点/订阅输出
4. 健康检查

这样不会陷入循环：如果重启后仍未进入 XanMod 内核，脚本会暂停并提示检查内核/GRUB，而不是继续重启。

## 常用命令

```bash
# 环境检测
bash scripts/vps-argo-vmess-oneclick.sh --check

# 只执行 TCP 优化
bash scripts/vps-argo-vmess-oneclick.sh --optimize

# 只安装 Argo VMess + WS
bash scripts/vps-argo-vmess-oneclick.sh --install-argo-vmess

# 一键执行：TCP 优化 + Argo VMess + WS
bash scripts/vps-argo-vmess-oneclick.sh --all

# 重启后继续完整流程
speed --continue

# 安装 speed 快捷命令
bash scripts/vps-argo-vmess-oneclick.sh --install-shortcut

# 查看节点 / 订阅 URL
bash scripts/vps-argo-vmess-oneclick.sh --show-url

# 输出结果摘要
bash scripts/vps-argo-vmess-oneclick.sh --summary

# 安装后健康检查
bash scripts/vps-argo-vmess-oneclick.sh --health

# 卸载 Argo VMess + WS
bash scripts/vps-argo-vmess-oneclick.sh --uninstall-argo
```

## 可配置环境变量

```bash
UUID=自定义UUID
WS_PATH=argox
START_PORT=30000
NGINX_PORT=8001
NODE_NAME=VPS-Argo-VMess
ARGO_DOMAIN=固定Argo域名
ARGO_AUTH='Argo Token 或 Json 或 Cloudflare API 信息'
SERVER=优选CDN地址
SERVER_PORT=443
```

示例：

```bash
WS_PATH=zaki NODE_NAME=Zaki-VPS bash scripts/vps-argo-vmess-oneclick.sh --install-argo-vmess
```

## V1 实现方式

### TCP 优化

文件：

```text
scripts/tcp-one-click-optimize.sh
```

来源于原 `net-tcp-tune.sh` 的菜单项：

```text
66. ⭐ 一键全自动优化 (BBR v3 + 网络调优)
```

执行逻辑保持原脚本一致：

- 如果当前不是 XanMod 内核：安装 XanMod + BBR v3，完成后提示重启
- 如果已经运行 XanMod 内核：自动执行网络优化流程
  - BBR 直连优化
  - DNS 净化
  - Realm 转发修复
  - 可选永久禁用 IPv6

### Argo VMess + WS

文件：

```text
scripts/upstream/argox.sh
```

V1 不直接大规模删减 ArgoX，而是通过非交互配置强制：

```bash
INSTALL_PROTOCOLS=(f)
```

其中 `f` 对应：

```text
VMess + WS
```

生成的核心配置：

```text
协议：VMess
传输：WebSocket
Path：/<WS_PATH>-vm
alterId：0
Argo：Cloudflare Tunnel
```

## 健康检查

```bash
bash scripts/vps-argo-vmess-oneclick.sh --health
```

会检查：

- `argo.service` 是否运行
- `xray.service` 是否运行
- Nginx / 本地入口端口是否监听
- `/etc/argox/list` 是否生成
- `/etc/argox/subscribe/base64` 是否生成
- 失败时输出对应修复方向

## 输出位置

```text
/etc/vps-argo-vmess/install.conf
/etc/vps-argo-vmess/install.log
/etc/argox/list
/etc/argox/subscribe/base64
/etc/argox/subscribe/clash
/etc/argox/subscribe/shadowrocket
```

## 审计文档

```text
docs/argox-vmess-ws-callchain.md
```

记录了 ArgoX 中 VMess + WS + Argo 的调用链、保留函数、后续瘦身方向。

## 上游脚本归档

```text
scripts/upstream/
  vps-tcp-tune-install-alias.sh
  net-tcp-tune.sh
  argox.sh
```

## 后续计划

- V2：把 ArgoX 中非 VMess+WS 协议逐步瘦身
- V2：把 TCP 66 依赖函数抽成更小核心模块
- V3：增加 dry-run、日志汇总、失败回滚提示、安装后健康检查
