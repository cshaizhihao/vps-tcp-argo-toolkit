# Speed Slayer

**BBR v3 网络调优 + Cloudflare Argo VMess WebSocket 隧道一键斩速器**

Speed Slayer 是一个面向 VPS 的专用一键工具，用来完成两件事：

1. **TCP 一键全自动优化**：XanMod / BBR v3 / 网络参数调优
2. **Argo 隧道节点生成**：只保留 VMess + WebSocket，并自动输出订阅 URL

它不是“大而全脚本合集”，而是把常用 VPS 加速链路收敛成一个可重复执行、可诊断、可续跑的工具。

---

## 核心特性

- 一键执行 TCP 优化：BBR v3 + 网络调优
- 自动处理 XanMod 内核安装后的重启续跑问题
- 提供 `speed` 快捷命令，类似原 TCP 脚本里的 `bbr`
- Argo 部分只启用 VMess + WebSocket，不安装多余协议
- 自动生成节点信息和订阅链接
- 提供环境检测、结果摘要、健康检查、一键诊断
- 支持 `speed --update-self` 从 GitHub 更新自身

---

## 仓库地址

```text
https://github.com/cshaizhihao/speed-slayer
```

---

## 一键安装 / 执行完整流程

```bash
curl -fsSL https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main/scripts/vps-argo-vmess-oneclick.sh -o /tmp/speed && bash /tmp/speed --all
```

首次执行时，如果 TCP 阶段安装了 XanMod / BBR v3 内核，脚本会提示重启。

重启后继续执行：

```bash
speed --continue
```

`speed --continue` 会继续完成：

1. TCP 网络调优第二阶段
2. Argo VMess + WS 安装
3. 节点 / 订阅 URL 输出
4. 健康检查

如果重启后仍未进入 XanMod 内核，脚本会暂停并提示检查内核/GRUB，避免陷入循环。

---

## 推荐使用流程

### 1. 首次运行

```bash
curl -fsSL https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main/scripts/vps-argo-vmess-oneclick.sh -o /tmp/speed && bash /tmp/speed --all
```

### 2. 如果提示重启

```bash
reboot
```

### 3. 重启后继续

```bash
speed --continue
```

### 4. 完成后诊断

```bash
speed --doctor
```

---

## 命令列表

```bash
speed --check                # 环境检测
speed --optimize             # 只执行 TCP 优化
speed --install-argo-vmess   # 只安装 Argo VMess + WS
speed --all                  # 智能全流程：TCP 优化 + Argo VMess + WS
speed --continue             # 重启后继续完整流程
speed --show-url             # 查看节点 / 订阅 URL
speed --summary              # 输出结果摘要
speed --health               # 安装后健康检查
speed --doctor               # 一键诊断：环境检测 + 结果摘要 + 健康检查
speed --install-shortcut     # 安装 speed 快捷命令
speed --update-self          # 更新 speed 自身
speed --clear-state          # 清理续跑状态
speed --uninstall-argo       # 卸载 Argo VMess + WS
```

如果尚未安装 `speed` 快捷命令，也可以用脚本路径执行：

```bash
bash scripts/vps-argo-vmess-oneclick.sh --doctor
```

---

## 功能说明

### Speed TCP：一键全自动优化

来源于上游 TCP 调优脚本菜单项：

```text
66. ⭐ 一键全自动优化 (BBR v3 + 网络调优)
```

执行逻辑：

- 如果当前不是 XanMod 内核：安装 XanMod + BBR v3，完成后提示重启
- 如果已经运行 XanMod 内核：自动执行网络优化流程
  - BBR 直连优化
  - DNS 净化
  - Realm 转发修复
  - 可选永久禁用 IPv6

### Argo VMess + WS 隧道

Argo 部分基于 ArgoX，但强制只启用：

```bash
INSTALL_PROTOCOLS=(f)
```

注意：脚本调用 ArgoX 时只使用 `-f config`，不会附加 `-l`。因为 ArgoX 的 `-l` 会触发极速安装逻辑，可能覆盖协议选择并安装多余协议。

其中 `f` 对应：

```text
VMess + WebSocket
```

生成配置：

```text
协议：VMess
传输：WebSocket
Path：/<WS_PATH>-vm
alterId：0
隧道：Cloudflare Argo Tunnel
```

---

## 重启续跑机制

原 TCP 脚本的设计是：

1. 第一次运行安装内核
2. 重启
3. 再输入 `bbr` 继续调优

Speed Slayer 对这个流程做了统一：

```bash
speed --all
```

如果需要重启，脚本会：

- 安装 `/usr/local/bin/speed` 快捷命令
- 写入续跑状态：`/etc/vps-argo-vmess/state.env`
- 提示重启

重启后执行：

```bash
speed --continue
```

它会继续完成 TCP 调优和 Argo 安装。

防循环保护：

- 重启后会检测 `uname -r | grep -qi xanmod`
- 如果没有进入 XanMod 内核，则停止继续执行
- 不会反复安装 / 反复重启 / 反复进入 Argo 阶段

---

## 一键诊断

```bash
speed --doctor
```

等价于：

```bash
speed --check
speed --summary
speed --health
```

检查内容包括：

- 当前内核
- 当前拥塞控制算法
- 当前默认队列算法
- `argo.service` 是否运行
- `xray.service` 是否运行
- Nginx / 本地入口端口是否监听
- `/etc/argox/list` 是否生成
- `/etc/argox/subscribe/base64` 是否生成
- 失败时输出修复方向

---

## 可配置环境变量

```bash
UUID=自定义UUID
WS_PATH=argox
START_PORT=30000
NGINX_PORT=8001
NODE_NAME=Speed-Slayer
ARGO_DOMAIN=固定Argo域名
ARGO_AUTH='Argo Token 或 Json 或 Cloudflare API 信息'
SERVER=优选CDN地址
SERVER_PORT=443
```

示例：

```bash
WS_PATH=zaki NODE_NAME=Zaki-Speed speed --install-argo-vmess
```

固定 Argo 隧道示例：

```bash
ARGO_DOMAIN=tunnel.example.com ARGO_AUTH='你的 Argo Token 或 Json' speed --install-argo-vmess
```

不填 `ARGO_DOMAIN` / `ARGO_AUTH` 时，默认走 Cloudflare 临时隧道。

---

## 输出位置

```text
/etc/vps-argo-vmess/install.conf
/etc/vps-argo-vmess/install.log
/etc/vps-argo-vmess/state.env
/etc/argox/list
/etc/argox/subscribe/base64
/etc/argox/subscribe/clash
/etc/argox/subscribe/shadowrocket
```

---

## 项目结构

```text
scripts/
  vps-argo-vmess-oneclick.sh      # 主入口脚本
  tcp-one-click-optimize.sh       # TCP 66 独立入口
  upstream/
    vps-tcp-tune-install-alias.sh # TCP 上游别名安装脚本归档
    net-tcp-tune.sh               # TCP 上游主脚本归档
    argox.sh                      # ArgoX 上游脚本归档

docs/
  argox-vmess-ws-callchain.md     # ArgoX VMess+WS 调用链审计
```

---

## 上游来源

### TCP 调优脚本

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?$(date +%s)")
```

### ArgoX 脚本

```bash
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh) -l
```

---

## 版本路线

### V1：可用整合版

- 统一入口脚本
- TCP 菜单 66 独立入口
- ArgoX 强制 VMess + WS
- 节点 / 订阅输出

### V1.1：体验增强版

- `speed` 快捷命令
- `--continue` 重启续跑
- `--check` 环境检测
- `--summary` 结果摘要
- `--health` 健康检查
- `--doctor` 一键诊断
- `--update-self` 自更新

### V2：瘦身版

- 删除 ArgoX 中非 VMess+WS 的协议逻辑
- 将 TCP 66 依赖函数抽成更小模块
- 降低脚本体积和复杂度

### V3：正式稳定版

- dry-run 模式
- 回滚提示
- 更完整日志
- 多系统测试矩阵
- 更清晰的错误码

---

## 当前状态

当前版本定位：**V1.1 可用增强版**。

优先目标是保证真实可用和可恢复执行，而不是过早删除上游脚本依赖。
