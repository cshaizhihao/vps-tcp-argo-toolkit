# Speed Slayer

> VPS 网络加速 · TCP 智能调优 · Argo 隧道 · VMess WebSocket 节点生成

**Speed Slayer** 是一个面向 VPS 的一键网络加速与节点部署工具。
它将 **XanMod / BBR v3 / TCP 智能调优**、**容器无内核降级模式**、**Cloudflare Argo Tunnel** 与 **VMess WebSocket 节点生成**整合到一个清晰、可重复执行、可诊断、可修复的流程中。

<p align="center">
  <strong>斩断延迟，撕开隧道，释放节点。</strong>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-v2.0.4-22c55e">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-0891b2">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-f97316">
  <img alt="Status" src="https://img.shields.io/badge/status-stable-16a34a">
</p>

---

## V2.0.4 修复说明

- 修复 `--menu` 只打开临时菜单但没有安装 `/usr/local/bin/speed` 快捷命令的问题。
- 现在通过安装入口执行 `--menu` 会先安装/刷新 `speed`，再进入主菜单。

---

## V2.0.3 修复说明

- 优化主菜单入口：执行 `speed` 时始终显示控制台，不再因续跑状态直接跳过菜单。
- 如果存在续跑状态，控制台顶部会提示可选择第 1 项继续，或执行 `speed --continue` 自动续跑。
- `--all` / `--force-all` 仍保持完整流程直达，适合无人值守安装。

---

## V2.0.2 修复说明

- 修复 XanMod 在 Ubuntu Jammy 等系统上使用发行版 codename 源时可能找不到 `linux-xanmod-*` 包的问题。
- 内核安装源现在优先使用 XanMod `releases` 仓库；如无可用包，再回退到系统 codename 仓库。
- 日志会显示 `[XanMod APT] repo suite`、`selected suite`，便于判断实际使用的仓库。

---

## V2.0.0 重点变化

- **流程拆分**：支持完整流程、单独 TCP 调优、单独 Argo 节点生成。
- **TCP 调优升级**：按带宽分档推荐 TCP buffer，并允许手动选择缓存档位。
- **容器兼容**：检测到容器环境时自动跳过 XanMod 内核安装，进入无内核降级模式。
- **XanMod 安装增强**：优化 GPG key 下载、APT 源 codename、包候选选择与日志提示。
- **可删除/可重装**：新增 Speed Slayer 删除/卸载功能，方便反复测试与排障。
- **控制台产品化**：菜单、健康检查、日志、提示语与输出样式全面优化。
- **短安装入口**：新增 `install.sh`，安装命令更短、更易传播。

---

## 功能特性

- **Speed Slayer TCP+Argo 完整流程**：TCP 调优 + Argo VMess WebSocket 节点部署。
- **一键 TCP 调优**：XanMod / BBR v3 / FQ / TCP buffer / DNS / limits / IPv6 策略。
- **一键 VMess+Argo 节点生成**：`cloudflared + Xray + Nginx + systemd` 原生部署。
- **真实测速**：集成 Ookla Speedtest，根据上传带宽推荐缓存档位。
- **手动缓存档位**：支持 16MB / 32MB / 64MB / 128MB / 256MB / 自定义。
- **容器降级模式**：容器小鸡不强装内核，只应用容器内可生效的优化项。
- **重复安装友好**：自动清理旧服务、旧进程、旧配置，并保留备份。
- **诊断与修复**：`doctor / logs / repair / speedtest / netcheck / health`。
- **自更新**：优先走 GitHub API，降低 raw CDN 缓存影响。
- **删除/卸载**：可清理 Speed Slayer 服务、配置、状态和快捷命令。

---

## 快速开始

### 推荐：完整流程 TCP + Argo

```bash
bash <(curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh) --all
```

如果你的环境不支持 `<(...)`：

```bash
curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh -o /tmp/speed-install && bash /tmp/speed-install --all
```

### 只安装并进入主菜单

```bash
bash <(curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh) --menu
```

兼容写法：

```bash
curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh -o /tmp/speed-install && bash /tmp/speed-install --menu
```

`--all` 会执行完整流程：TCP 调优 + Argo VMess+WS 节点生成。如只想打开控制台，请安装后执行 `speed`，或使用 `--menu`。

---

## 分流程运行

### 只做 TCP 调优

```bash
bash <(curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh) --tcp
```

安装快捷命令后也可以执行：

```bash
speed --tcp
```

### 只部署 Argo VMess+WS 节点

```bash
bash <(curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh) --argo
```

安装快捷命令后也可以执行：

```bash
speed --argo
```

### 完整流程：TCP + Argo

```bash
bash <(curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh) --all
```

或进入控制台选择：

```text
1. Speed Slayer TCP+Argo 🚀
```

---

## 控制台首页

```text
『Speed Slayer 控制台』

1. Speed Slayer TCP+Argo 🚀
2. 一键TCP调优
3. 一键Vmess+Argo 节点生成
4. 诊断与日志
5. 修复/清理/卸载
6. 更新
0. 退出
```

---

## 常用命令

```bash
speed                  # 打开控制台；如有续跑状态会提示但不跳过菜单
speed --version        # 查看版本
speed --update-self    # 更新 speed 自身

speed --tcp            # 单独执行 TCP 调优
speed --optimize       # 等同 speed --tcp
speed --argo           # 单独部署 Argo VMess+WS 节点
speed --force-all      # 完整流程：TCP 调优 + Argo 节点
speed --continue       # 根据续跑状态自动继续完整流程

speed --doctor         # 全链路诊断
speed --health         # 安装后健康检查
speed --logs           # 查看日志菜单
speed --speedtest      # Ookla Speedtest 测速
speed --netcheck       # DNS / GitHub / Cloudflare / 出站连通性检测

speed --repair         # 清理残留并重装 Argo VMess+WS
speed --uninstall      # 删除 / 卸载 Speed Slayer
speed --clear-state    # 清理重启续跑状态
```

---

## TCP 智能调优说明

Speed Slayer 的 TCP 调优流程包含：

1. 检测系统环境、内核、容器状态。
2. 如为普通 VPS 且未进入 XanMod，尝试安装 XanMod / BBR v3 内核。
3. 如为容器环境，自动跳过内核安装，进入无内核降级模式。
4. 检测 SWAP、内存和 Speedtest 上传带宽。
5. 根据带宽分档推荐 TCP buffer，并允许手动选择。
6. 清理冲突 sysctl 配置。
7. 写入 BBR / FQ / TCP buffer / backlog / keepalive / limits / DNS 参数。
8. 应用 FQ 队列与持久化限制。
9. 输出 TCP 状态摘要。

### TCP buffer 推荐档位

| 带宽 | 推荐缓存 |
|---|---:|
| ≤100Mbps | 16MB |
| 100-500Mbps | 32MB |
| 500Mbps-1Gbps | 64MB |
| 1Gbps-2.5Gbps | 128MB |
| ≥2.5Gbps | 256MB |

脚本还会根据内存做保护，避免小内存 VPS 因缓存过大导致压力过高。

### 手动指定带宽

```bash
SPEED_BANDWIDTH_MBPS=2000 speed --tcp
```

### 关闭自动测速

```bash
SPEED_AUTO_SPEEDTEST=0 speed --tcp
```

带宽来源会显示为：

- `measured`：Ookla Speedtest 实测
- `manual`：手动指定
- `default`：测速失败或关闭测速后的默认值

---

## 容器与 IPv6 小鸡说明

部分 IPv6-only 容器小鸡无法安装或切换 XanMod 内核，这是容器/宿主机限制，不是脚本失败。

Speed Slayer 会自动检测容器环境：

- 容器环境：跳过 XanMod 内核安装，进入无内核降级模式。
- 普通 VPS：尝试安装 XanMod / BBR v3 内核，必要时提示重启。

容器降级模式只应用容器内可生效的网络配置；部分 sysctl 项可能因权限不足被系统拒绝，脚本会保留可生效项并继续执行。

---

## Argo VMess WebSocket 节点

Speed Slayer 原生部署：

- `cloudflared`
- `Xray VMess + WebSocket`
- `Nginx WebSocket 反代与订阅接口`
- `systemd` 服务

安装完成后输出：

- VMess URL
- Base64 订阅
- Clash 订阅
- Shadowrocket 订阅
- Auto 订阅

只部署节点：

```bash
speed --argo
```

---

## 重复安装、修复与删除

### 修复 Argo 安装

```bash
speed --repair
```

会清理 Argo 服务、旧进程和旧配置，然后重新部署 VMess+WS。

### 删除 / 卸载 Speed Slayer

```bash
speed --uninstall
```

删除功能会清理：

- `/usr/local/bin/speed`
- `/etc/vps-argo-vmess`（备份为 `.bak.<timestamp>`）
- `/etc/argox`（备份为 `.bak.<timestamp>`）
- `argo.service` / `xray.service`
- Speed Slayer 写入的 sysctl、systemd limits、DNS、IPv6 配置

注意：**不会自动卸载 XanMod 内核本身**，避免误删系统内核导致机器无法启动。

删除确认默认为 `N`，必须明确输入 `y` 或 `yes` 才会执行。

---

## 诊断与日志

```bash
speed --doctor
speed --health
speed --logs
speed --netcheck
speed --speedtest
```

常见日志路径：

```text
/etc/vps-argo-vmess/install.log
/etc/vps-argo-vmess/kernel-install.log
/etc/vps-argo-vmess/tcp-optimize.log
/etc/vps-argo-vmess/speedtest.log
/etc/vps-argo-vmess/netcheck.log
/etc/argox/argo.log
/etc/argox/xray-error.log
```

XanMod 安装失败时，优先查看：

```bash
cat /etc/vps-argo-vmess/kernel-install.log
```

---

## 更新

推荐：

```bash
speed --update-self
```

如果本机脚本损坏，可重新拉取短安装入口：

```bash
curl -fsSL https://github.com/cshaizhihao/speed-slayer/raw/main/install.sh -o /tmp/speed-install && bash /tmp/speed-install --all
```

---

## CDN 优选建议

节点生成后，建议在本地运行 CloudflareSpeedTest，选择延迟更低、速度更稳的 CDN IP：

<https://github.com/XIU2/CloudflareSpeedTest>

---

## 鸣谢

特别感谢 **@Eric86777** 的 TCP 调优思路与实践参考。

- NodeSeek 帖子：<https://www.nodeseek.com/post-704739-1>
- 项目仓库：<https://github.com/Eric86777/vps-tcp-tune>

Speed Slayer 的 TCP 调优方向参考了他的思路，并在此基础上做了产品化控制台、续跑机制、诊断修复、Argo VMess WebSocket 部署与订阅输出等整合。

---

## 版本

当前正式版：`v2.0.4`

---

## License

MIT or repository default license. See repository files for details.
