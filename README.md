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

### 常用命令

```bash
# 只执行 TCP 优化
bash scripts/vps-argo-vmess-oneclick.sh --optimize

# 只安装 Argo VMess + WS
bash scripts/vps-argo-vmess-oneclick.sh --install-argo-vmess

# 一键执行：TCP 优化 + Argo VMess + WS
bash scripts/vps-argo-vmess-oneclick.sh --all

# 查看节点 / 订阅 URL
bash scripts/vps-argo-vmess-oneclick.sh --show-url

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
