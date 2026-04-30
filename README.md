# Speed Slayer

> VPS 网络加速 · Argo 隧道 · VMess WebSocket 订阅一键生成

**Speed Slayer** 是一个面向 VPS 的一键网络加速与节点部署工具。它将 **XanMod / BBR v3 / TCP 智能调优** 与 **Cloudflare Argo Tunnel + VMess WebSocket** 收敛到一个清晰、可重复执行、可诊断、可修复的流程中。

<p align="center">
  <strong>斩断延迟，撕开隧道，释放节点。</strong>
</p>

<p align="center">
  <img alt="Version" src="https://img.shields.io/badge/version-v1.0.0-22c55e">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash-0891b2">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Debian%20%7C%20Ubuntu-f97316">
  <img alt="Status" src="https://img.shields.io/badge/status-stable-16a34a">
</p>

---

## 特性

- **一键完整流程**：TCP 调优 + Argo VMess WebSocket 节点部署
- **XanMod / BBR v3**：自动安装内核组件，重启后输入 `speed` 自动续跑
- **智能 TCP 调优**：检测内存、SWAP、带宽，动态计算 TCP buffer
- **真实测速**：集成 Ookla Speedtest，多服务器重试，失败不阻断安装
- **原生 Argo VMess+WS**：`cloudflared + Xray + Nginx + systemd`
- **订阅输出**：VMess URL、Base64、Clash、Shadowrocket、Auto
- **重复安装友好**：自动清理旧服务、旧进程、旧配置并备份
- **诊断与修复**：`doctor / logs / repair / speedtest / netcheck`
- **自更新**：优先走 GitHub API，减少 raw CDN 缓存影响
- **中文控制台 UI**：结果页、日志路径、下一步建议清晰可读

---

## 快速开始

```bash
curl -fsSL -H "Accept: application/vnd.github.raw" -H "Cache-Control: no-cache" "https://api.github.com/repos/cshaizhihao/speed-slayer/contents/scripts/vps-argo-vmess-oneclick.sh?ref=main&ts=$(date +%s)" -o /tmp/speed && bash /tmp/speed --all
```

首次运行 `--all` 会进入安全主页，不会立即修改系统。选择完整流程后，脚本会按阶段执行，并在关键操作前给出确认。

安装快捷命令后，后续直接输入：

```bash
speed
```

---

## 控制台

```text
『Speed Slayer 控制台』

  1. 一键执行完整流程        2. 节点管理
  3. TCP 加速                4. 诊断与日志
  5. 修复与清理              6. 更新
  0. 退出
```

---

## 常用命令

```bash
speed                  # 打开控制台；重启后自动续跑
speed --update-self    # 更新 speed 自身
speed --version        # 查看版本
speed --doctor         # 全链路诊断
speed --logs           # 查看日志菜单
speed --repair         # 清理残留并重装 Argo VMess+WS
speed --speedtest      # Ookla Speedtest 测速
speed --netcheck       # DNS / GitHub / Cloudflare / 出站连通性检测
```

---

## 完整流程

1. 安装 `speed` 快捷命令
2. 检测系统环境、内核、TCP 状态
3. 如未进入 XanMod 内核，安装 XanMod / BBR v3 内核组件
4. 内核安装完成后询问是否立即重启
5. 重启后输入 `speed`，自动识别续跑状态
6. 执行 TCP 智能调优
7. 部署 Argo VMess WebSocket 节点
8. 生成节点与订阅链接
9. 执行健康检查
10. 输出安装完成结果页与 Cloudflare CDN 优选建议

---

## TCP 智能调优

Speed Slayer 会按以下步骤执行 TCP 调优：

1. 检测虚拟内存（SWAP）与物理内存
2. 执行 Speedtest 或读取手动带宽
3. 根据带宽、内存与地区动态计算 TCP buffer
4. 清理冲突的 sysctl 配置
5. 写入 BBR / FQ / TCP buffer / backlog / keepalive / limits / DNS 参数
6. 应用 FQ 队列、systemd limits、IPv6 策略
7. 验证 BBR / FQ / buffer 状态

可手动指定带宽和地区：

```bash
SPEED_BANDWIDTH_MBPS=2000 SPEED_REGION=global speed --optimize
SPEED_AUTO_SPEEDTEST=0 speed --optimize
```

带宽来源会明确显示：

- `measured`：Ookla Speedtest 实测
- `manual`：手动指定
- `default`：测速失败或关闭测速后回退默认值

---

## Argo VMess WebSocket

Speed Slayer 原生部署以下组件：

- `cloudflared`
- `Xray VMess + WebSocket`
- `Nginx WebSocket 反代与订阅接口`
- `systemd` 服务

安装完成后会输出：

- VMess URL
- Base64 订阅
- Clash 订阅
- Shadowrocket 订阅
- Auto 订阅

---

## 重复安装与修复

同一台机器重复安装时，Speed Slayer 会自动：

- 停止并禁用旧 `argo` / `xray` 服务
- 清理旧 `cloudflared` / `xray` / 独立 Nginx 进程
- 备份旧 `/etc/argox` 到 `/etc/argox.bak.<timestamp>`
- 重建干净配置目录
- 对 VMess+WS 配置做 JSON 级校验

手动修复：

```bash
speed --repair
```

---

## 诊断与日志

```bash
speed --doctor
speed --logs
speed --netcheck
speed --speedtest
```

日志路径：

```text
/etc/vps-argo-vmess/install.log
/etc/vps-argo-vmess/kernel-install.log
/etc/vps-argo-vmess/tcp-optimize.log
/etc/vps-argo-vmess/speedtest.log
/etc/vps-argo-vmess/netcheck.log
/etc/argox/argo.log
/etc/argox/xray-error.log
```

---

## 更新

推荐：

```bash
speed --update-self
```

如果本机脚本损坏，可强制覆盖：

```bash
curl -fsSL -H "Accept: application/vnd.github.raw" -H "Cache-Control: no-cache" "https://api.github.com/repos/cshaizhihao/speed-slayer/contents/scripts/vps-argo-vmess-oneclick.sh?ref=main&ts=$(date +%s)" -o /usr/local/bin/speed && chmod +x /usr/local/bin/speed
```

---

## CDN 优选建议

节点生成后，建议在本地运行 CloudflareSpeedTest，选择延迟更低、速度更稳的 CDN IP：

<https://github.com/XIU2/CloudflareSpeedTest/releases>

---

## 鸣谢

特别感谢 **@Eric86777** 的 TCP 调优思路与实践参考。

- NodeSeek 帖子：<https://www.nodeseek.com/post-704739-1>
- 项目仓库：<https://github.com/Eric86777/vps-tcp-tune>

Speed Slayer 的 TCP 调优方向参考了他的思路，并在此基础上做了产品化控制台、续跑机制、诊断修复、Argo VMess WebSocket 部署与订阅输出等整合。

---

## 版本

当前稳定版：`v1.0.0`

---

## License

MIT or repository default license. See repository files for details.

## v1.0.1-beta 内测说明

当前内测分支：`beta/v1.0.1-tcp-buffer-tuning`

本轮优先修复 1.0 版本里「TCP 一键调优无感」的问题：

- TCP 缓存不再使用过小/固定模板。
- 新增按带宽自动匹配缓存档位：
  - ≤100Mbps → 16MB
  - 100-500Mbps → 32MB
  - 500Mbps-1Gbps → 64MB
  - 1Gbps-2.5Gbps → 128MB
  - ≥5Gbps/10Gbps → 256MB（高级/实验档）
- 新增小内存保护，避免低配 VPS 因缓存过激影响稳定。
- 新增高级手动缓存输入，便于内测对比。
- 保留执行后 sysctl 生效校验。

内测安装：

```bash
curl -fsSL "https://raw.githubusercontent.com/cshaizhihao/speed-slayer/beta/v1.0.1-tcp-buffer-tuning/scripts/tcp-one-click-optimize.sh?ts=$(date +%s)" -o /tmp/speed-slayer-beta && bash /tmp/speed-slayer-beta
```

国内网络可尝试：

```bash
curl -fsSL "https://gh-proxy.com/https://raw.githubusercontent.com/cshaizhihao/speed-slayer/beta/v1.0.1-tcp-buffer-tuning/scripts/tcp-one-click-optimize.sh?ts=$(date +%s)" -o /tmp/speed-slayer-beta && bash /tmp/speed-slayer-beta
```
