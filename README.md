# Speed Slayer

**BBR v3 网络调优 + Cloudflare Argo VMess WebSocket 隧道一键斩速器**

Speed Slayer 是一个面向 VPS 的专用一键工具。

**Author: NodeSeek @cshaizhihao**

它用来完成两件事：

1. **TCP 一键全自动优化**：XanMod / BBR v3 / 网络参数调优
2. **Argo 隧道节点生成**：只保留 VMess + WebSocket，并自动输出订阅 URL

它不是“大而全脚本合集”，而是把常用 VPS 加速链路收敛成一个可重复执行、可诊断、可续跑的工具。

---

## 核心特性

- 彩色 `SPEED SLAYER` 启动艺术字
- 彩色状态输出：INFO / DONE / WARN / ERR
- 阶段化安装进度：依赖、二进制、配置、服务、隧道、订阅


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
curl -fsSL "https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o /tmp/speed && bash /tmp/speed --all
```

首次执行 `--all` 会进入交互主页，不会直接修改系统。选择 TCP 优化时，会先出现 Y/N 确认，默认回车为 Y，然后才进入 BBR/TCP 调优。若需要无人值守完整流程，可使用 `speed --force-all`。

如果 TCP 阶段安装了 XanMod / BBR v3 内核，脚本会提示重启。

重启后继续执行：

```bash
speed
```

`speed` 会自动识别续跑状态并继续完成。

续跑阶段会完成：

1. TCP 网络调优第二阶段
2. Argo VMess + WS 安装
3. 节点 / 订阅 URL 输出
4. 健康检查

如果重启后仍未进入 XanMod 内核，脚本会暂停并提示检查内核/GRUB，避免陷入循环。

---

## 更新 speed

如果你已经安装过 `/usr/local/bin/speed`，建议先更新：

```bash
speed --update-self
```

如果 `speed --update-self` 无法执行，可强制覆盖：

```bash
curl -fsSL "https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o /usr/local/bin/speed && chmod +x /usr/local/bin/speed
```

## 推荐使用流程

### 1. 首次运行

```bash
curl -fsSL "https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o /tmp/speed && bash /tmp/speed --all
```

### 2. 如果提示重启

```bash
reboot
```

### 3. 重启后继续

```bash
speed
```

### 4. 完成后诊断

```bash
speed --doctor
```

---

## 菜单逻辑

`--all` 会进入主页；主页 **1 号选项** 是完整流程（TCP 优化 + Argo VMess + WS）。脚本标题只渲染一次，子流程不会重复打印两个 `SPEED SLAYER` 标题。

## 命令列表

```bash
speed --tcp-status           # 查看 TCP / BBR / 内核状态
speed --check                # 环境检测
speed --optimize             # 进入 Speed Slayer TCP 施工面板后执行优化
speed --install-argo-vmess   # 只安装 Argo VMess + WS
speed --all                  # 显示交互主页（安全默认，菜单 1 为完整流程）
speed --force-all            # 无人值守完整流程：TCP 优化 + Argo VMess + WS
speed                         # 默认入口；检测到续跑状态时自动继续
speed --continue             # 重启后继续完整流程
speed --show-url             # 查看节点 / 订阅 URL
speed --summary              # 输出结果摘要
speed --health               # 安装后健康检查
speed --doctor               # 全链路诊断：环境、服务、端口、配置、订阅、TCP
speed --logs                 # 日志菜单
speed --logs argo            # 直接查看 Argo 日志
speed --repair               # 清理残留并重装 Argo VMess+WS
speed --roadmap              # 查看项目进度与下一步计划
speed --install-shortcut     # 安装 speed 快捷命令
speed --update-self          # 更新 speed 自身
speed --version              # 查看当前版本
speed --clear-state          # 清理续跑状态
speed --clean-argo           # 清理 Argo 配置，备份后重装 VMess+WS
speed --uninstall-argo       # 卸载 Argo VMess + WS
```

如果尚未安装 `speed` 快捷命令，也可以用脚本路径执行：

```bash
bash scripts/vps-argo-vmess-oneclick.sh --doctor
```

---

## 安装完成结果页

安装完成后会输出复制友好的结果页：

```text
Speed Slayer · Installation Complete
Protocol    VMess
Network     WebSocket
TLS         Enabled
Host/SNI    xxx.trycloudflare.com
Path        /xxx-vm
UUID        xxxxxxxx

VMess URL
vmess://...

Subscriptions
Base64       https://xxx/base64
Clash        https://xxx/clash
Shadowrocket https://xxx/shadowrocket
Auto         https://xxx/auto
```

## 修复与日志

```bash
speed --logs
speed --logs install
speed --logs kernel
speed --logs tcp
speed --logs argo
speed --logs xray
speed --repair
```

`--repair` 会执行清理、备份和 Argo VMess+WS 重装，适合重复安装失败或残留污染场景。

## 重复安装与自动清理

Speed Slayer 支持在同一台机器上重复安装。安装 Argo VMess+WS 前会自动执行预清理：

- 停止并禁用 `argo` / `xray` 服务
- 清理 `/etc/argox/cloudflared`、`/etc/argox/xray`、独立 Nginx 进程
- 备份旧 `/etc/argox` 到 `/etc/argox.bak.<timestamp>`
- 重建干净的 `/etc/argox` 与订阅目录
- 使用 JSON 级校验确认最终只存在一个 `vmess + ws` inbound
- 安装前检查 Nginx 入口端口和 Xray 内部端口占用
- 失败时输出日志路径、Argo/Xray 日志和最近备份路径

## XanMod 包名自动探测

内核安装会先根据 CPU x86-64-v 等级选择最合适的 XanMod 包，并通过 `apt-cache policy` 验证候选包是否存在。若目标等级包不可用，会自动降级到可用候选或通用 `linux-xanmod`；仍失败时会输出可用包列表和日志路径。

## 控制台菜单

主页已收拢为二级菜单：

```text
Speed Slayer · 控制台
1. 一键执行完整流程
2. 节点管理
3. TCP 加速
4. 诊断与日志
5. 修复与清理
6. 更新与项目进度
0. 退出
```

这样主入口保持简洁，高频功能进入对应二级页。

## 视觉与交互

脚本启动会显示彩色 `SPEED SLAYER` ASCII 艺术字，并使用统一的彩色状态输出。Argo 安装阶段显示清晰的阶段进度：

```text
[ 10%] 安装基础依赖
[ 25%] 下载 / 校验 cloudflared 与 Xray-core
[ 45%] 写入纯 VMess+WS Xray 配置
[ 55%] 写入 Nginx WebSocket 反代与订阅接口
[ 65%] 写入 systemd 服务
[ 75%] 启动 Xray / Nginx / Cloudflared
[ 88%] 获取 Argo 隧道域名
[ 96%] 生成 VMess URL 与订阅文件
[100%] 完成
```

完整日志仍写入：

```text
/etc/vps-argo-vmess/install.log
```

## 功能说明

### Speed TCP：一键全自动优化

执行逻辑：

- 如果当前不是 XanMod 内核：安装 XanMod + BBR v3，完成后提示重启
- 如果已经运行 XanMod 内核：自动执行网络优化流程
  - BBR 直连优化
  - DNS 净化
  - Realm 转发修复
  - 可选永久禁用 IPv6

### Argo VMess + WS 隧道

Argo 部分由 Speed Slayer 自动完成：

```text
cloudflared 下载/启动
Xray-core 下载/启动
纯 VMess + WebSocket inbound
Nginx WebSocket 反代
trycloudflare.com 临时隧道域名获取
VMess URL / base64 / clash / shadowrocket 订阅生成
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
speed
```

它会自动识别 `/etc/vps-argo-vmess/state.env`，继续完成 TCP 调优和 Argo 安装。

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
- 是否存在非 VMess+WS 协议残留
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
  lib/
    tcp-core.sh                    # TCP 核心函数库
  upstream/
    vps-tcp-tune-install-alias.sh # 历史参考
    net-tcp-tune.sh               # 历史参考
    argox.sh                      # 历史参考

docs/
  argox-vmess-ws-callchain.md     # 历史审计记录
```

---

## 历史参考

### TCP 调优脚本

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?$(date +%s)")
```

### Argo 隧道脚本参考

历史调研参考，当前主流程由 Speed Slayer 自身完成。

---

## 版本路线

### V1：可用整合版

- 统一入口脚本
- TCP 菜单 66 独立入口
- Speed Slayer Argo VMess + WS
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

- 进一步收敛主脚本体积
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

当前版本定位：**V1.3 Speed Slayer 增强版**。

本版本重点修复：

- `speed` 默认即可重启后续跑
- Argo 安装使用进度条 + 日志落盘
- Argo VMess+WS 由 Speed Slayer 自动部署
- 自动生成 Xray VMess+WS inbound、Nginx WS 反代、cloudflared systemd 服务
- 自动生成 VMess URL、base64、clash、shadowrocket 订阅文件
- 安装后强校验只能存在 VMess+WS，检测到 Reality/Hysteria/VLESS/Trojan/SS/XHTTP 等残留会直接失败
- 增加 `speed --clean-argo` 清理 Argo 配置

优先目标是保证真实可用、交互清晰、可恢复执行。


## 当前施工进度

当前进度约 **88%**。

- 可用 Beta：已接近，可进入实机回归
- 接近 V1.0：约 3 轮施工

后续每轮推送固定汇报：

1. 本轮完成
2. 下一轮做什么
3. 距离整体完成还剩多久
