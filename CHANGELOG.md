# CHANGELOG

## v1.0.0 - 2026-04-28

### Added
- 正式稳定版发布。
- README 正式化与项目说明美化。
- 鸣谢 @Eric86777 的 TCP 调优思路、NodeSeek 帖子与 vps-tcp-tune 仓库。

### Changed
- 版本号从 `v0.9.0-beta` 升级为 `v1.0.0`。
- README 聚焦快速开始、控制台、TCP 智能调优、Argo VMess WebSocket、诊断修复与更新说明。

### Notes
- v1.0.0 已通过实机测试，后续进入 bugfix 与兼容性增强阶段。

## v0.9.0-beta - 2026-04-28

### Added
- Speed Slayer 控制台与 `speed` 快捷命令。
- 一键完整流程：TCP 智能调优 + Argo VMess WebSocket 节点部署。
- XanMod / BBR v3 内核安装与重启后自动续跑。
- TCP 智能调优：内存/SWAP 检测、Speedtest 带宽探测、动态 buffer、FQ 队列、limits、DNS、IPv6 策略。
- 原生 Argo VMess+WS：cloudflared + Xray + Nginx + systemd。
- VMess URL、Base64、Clash、Shadowrocket、Auto 订阅生成。
- `speed --doctor` 全链路诊断。
- `speed --logs` 日志菜单。
- `speed --repair` 重复安装修复。
- `speed --speedtest` Ookla Speedtest 测速。
- `speed --netcheck` 网络连通性检测。
- 安装完成结果页与 CDN 优选提示。

### Changed
- 首页 UI 中文化与控制台二级菜单收拢。
- 自更新优先使用 GitHub API raw contents，减少 raw CDN 缓存影响。
- TCP 调优前台分阶段显示并同步写入日志。
- 重复安装前自动清理旧服务、旧进程与旧配置。

### Fixed
- 修复 `printf` 百分号导致脚本退出。
- 修复 VMess-only 校验误判 `vmess-ws` 为 `ss-ws` 残留。
- 修复 XanMod 包名硬拼导致的安装验证失败，改为 apt 候选探测与 fallback。
- 修复内核安装完成后未交互确认重启的问题。
- 修复更新提示把旧版本误判为新版本的问题。
- 修复终端 UI 颜色变量未定义问题。

### Notes
- 这是 Beta 版本，主流程已可用；建议继续进行多系统实机回归。
