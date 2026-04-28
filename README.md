# VPS TCP Tune + Argo Toolkit

用于存放并后续融合两个上游一键脚本：

1. TCP 调优脚本：Eric86777/vps-tcp-tune
2. Argo 一键脚本：fscarmen/argox

> 当前阶段仅归档上游脚本原文，暂不修改逻辑。后续会根据需求合并为统一入口脚本。

## 原始安装命令

### TCP 调优脚本

```bash
bash <(curl -fsSL "https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?$(date +%s)")
```

### Argo 一键脚本

```bash
bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh) -l
```

## 仓库结构

```text
scripts/
  upstream/
    vps-tcp-tune-install-alias.sh
    argox.sh
```

## 后续计划

- 设计统一入口脚本
- 保留 TCP 调优与 Argo 安装的独立执行能力
- 增加环境检测、参数菜单、日志、回滚/卸载说明
