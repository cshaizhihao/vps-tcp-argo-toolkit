#!/usr/bin/env bash
set -euo pipefail

# Speed Slayer
# Native Speed Slayer installer.
# - TCP optimize: uses the preserved TCP menu-66 entry.
# - Argo VMess+WS: native cloudflared + Xray + Nginx implementation, no ArgoX install chain.

REPO_RAW_BASE="https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main"
SPEED_SLAYER_VERSION="2026.04.28-r1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd 2>/dev/null || echo .)"

TCP_SCRIPT_LOCAL="${SCRIPT_DIR}/tcp-one-click-optimize.sh"
TCP_CORE_LIB_LOCAL="${SCRIPT_DIR}/lib/tcp-core.sh"

WORK_DIR="/etc/vps-argo-vmess"
CONFIG_FILE="${WORK_DIR}/install.conf"
LOG_FILE="${WORK_DIR}/install.log"
STATE_FILE="${WORK_DIR}/state.env"
INSTALLED_BIN="/usr/local/bin/speed"

DEFAULT_START_PORT="30000"
DEFAULT_NGINX_PORT="8001"
DEFAULT_WS_PATH="argox"
DEFAULT_NODE_NAME="VPS-Argo-VMess"

if [ -t 1 ]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'; C_DIM='\033[2m'
  C_RED='\033[31m'; C_GREEN='\033[32m'; C_YELLOW='\033[33m'; C_BLUE='\033[34m'; C_MAGENTA='\033[35m'; C_CYAN='\033[36m'; C_WHITE='\033[97m'
else
  C_RESET=''; C_BOLD=''; C_DIM=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''; C_MAGENTA=''; C_CYAN=''; C_WHITE=''
fi

cecho() { printf "%b%s%b\n" "$1" "$2" "$C_RESET"; }
info() { printf "%b◆ INFO%b %s\n" "$C_CYAN" "$C_RESET" "$*"; }
success() { printf "%b◆ DONE%b %s\n" "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf "%b◆ WARN%b %s\n" "$C_YELLOW" "$C_RESET" "$*"; }
err() { printf "%b◆ ERR %b %s\n" "$C_RED" "$C_RESET" "$*" >&2; }

line() { printf "%b%s%b\n" "$C_MAGENTA" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$C_RESET"; }
section() { echo ""; line; printf "%b%s%b\n" "$C_BOLD$C_CYAN" " $1" "$C_RESET"; line; }

banner() {
  printf "%b" "$C_BOLD$C_MAGENTA"
  cat <<'EOF'
   _____ ____  ______ ______ ____     _____ __    ___   __  __________ 
  / ___// __ \/ ____// ____// __ \   / ___// /   /   | / / / / ____/ __ \
  \__ \/ /_/ / __/  / __/  / / / /   \__ \/ /   / /| |/ /_/ / __/ / /_/ /
 ___/ / ____/ /___ / /___ / /_/ /   ___/ / /___/ ___ / __  / /___/ _, _/ 
/____/_/   /_____//_____/_____/   /____/_____/_/  |_/_/ /_/_____/_/ |_|  
EOF
  printf "%b" "$C_RESET"
  printf "%b%s%b\n" "$C_DIM" "        Native BBR v3 + Argo VMess WebSocket one-click accelerator" "$C_RESET"
}

intro() {
  printf "%b%s%b\n" "$C_CYAN" "  Speed Slayer 是一个 VPS 网络加速与 Argo 隧道一键脚本。" "$C_RESET"
  printf "%b%s%b\n" "$C_WHITE" "  功能：BBR v3 网络优化 + Cloudflare Argo VMess WebSocket 节点生成。" "$C_RESET"
  printf "%b%s%b\n" "$C_DIM" "  Version: ${SPEED_SLAYER_VERSION} | Author: NodeSeek @cshaizhihao" "$C_RESET"
  echo ""
}

render_header_once() {
  if [ "${SPEED_HEADER_RENDERED:-0}" = "1" ]; then
    return 0
  fi
  SPEED_HEADER_RENDERED=1
  banner
  intro
}

require_root() {
  if [ "$(id -u)" != "0" ]; then
    err "请使用 root 执行：sudo -i 后重新运行"
    exit 1
  fi
}

confirm_action() {
  local prompt="$1"
  local ans
  if [ "${ASSUME_Y:-0}" = "1" ]; then
    return 0
  fi
  printf "%b?%b %s %b[Y/n]%b " "$C_YELLOW" "$C_RESET" "$prompt" "$C_GREEN" "$C_RESET"
  read -r ans || ans=""
  ans="${ans:-Y}"
  [[ "$ans" =~ ^[Yy]$ ]]
}

download_script() {
  local raw_path="$1"
  local out
  out="$(mktemp /tmp/speed-slayer.XXXXXX.sh)"
  curl -fsSL "${REPO_RAW_BASE}/${raw_path}" -o "$out"
  bash -n "$out"
  chmod +x "$out"
  echo "$out"
}

fetch_or_run_script() {
  local local_path="$1"
  local raw_path="$2"
  shift 2
  if [ -s "$local_path" ]; then
    bash "$local_path" "$@"
  else
    local tmp_script
    tmp_script="$(download_script "$raw_path")"
    bash "$tmp_script" "$@"
  fi
}

install_shortcut() {
  require_root
  mkdir -p "$WORK_DIR"
  if [ -s "${BASH_SOURCE[0]}" ]; then
    local src_path dst_path
    src_path="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
    dst_path="$(readlink -f "$INSTALLED_BIN" 2>/dev/null || echo "$INSTALLED_BIN")"
    if [ "$src_path" != "$dst_path" ]; then
      cp "${BASH_SOURCE[0]}" "$INSTALLED_BIN"
    else
      curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o "$INSTALLED_BIN.tmp"
      bash -n "$INSTALLED_BIN.tmp"
      mv "$INSTALLED_BIN.tmp" "$INSTALLED_BIN"
    fi
  else
    curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o "$INSTALLED_BIN"
  fi
  chmod +x "$INSTALLED_BIN"
  success "已安装快捷命令：speed"
  echo "以后可直接执行："
  echo "  speed"
  echo "  speed --force-all"
}

save_pending_state() {
  require_root
  mkdir -p "$WORK_DIR"
  cat > "$STATE_FILE" <<EOF
PENDING_CONTINUE=1
CREATED_AT=$(date -Is 2>/dev/null || date)
NEXT_ACTION=continue
EOF
  chmod 600 "$STATE_FILE"
}

clear_state() {
  require_root
  rm -f "$STATE_FILE"
  success "已清理续跑状态：$STATE_FILE"
}

is_xanmod_kernel() {
  uname -r | grep -qi xanmod
}

show_continue_hint() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " 下一步"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "如果本次安装了 XanMod/BBR v3 内核，请重启服务器。"
  echo "重启后只需要执行："
  echo ""
  echo "  speed"
  echo ""
  echo "Speed Slayer 会自动识别续跑状态，继续完成：TCP 网络调优 + Argo VMess+WS 安装 + 健康检查。"
}

run_with_progress() {
  local title="$1"
  shift
  local log_file="$1"
  shift
  mkdir -p "$(dirname "$log_file")"
  section "$title"
  "$@" >"$log_file" 2>&1 &
  local pid=$!
  local frames=('▱▱▱▱▱▱▱▱▱▱ 0%' '▰▱▱▱▱▱▱▱▱▱ 10%' '▰▰▱▱▱▱▱▱▱▱ 20%' '▰▰▰▱▱▱▱▱▱▱ 30%' '▰▰▰▰▱▱▱▱▱▱ 40%' '▰▰▰▰▰▱▱▱▱▱ 50%' '▰▰▰▰▰▰▱▱▱▱ 60%' '▰▰▰▰▰▰▰▱▱▱ 70%' '▰▰▰▰▰▰▰▰▱▱ 80%' '▰▰▰▰▰▰▰▰▰▱ 90%')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r%b◆ RUN %b%s" "$C_CYAN" "$C_RESET" "${frames[$((i % ${#frames[@]}))]}"
    i=$((i + 1))
    sleep 1
  done
  set +e
  wait "$pid"
  local code=$?
  set -e
  if [ "$code" -eq 0 ]; then
    printf "\r%b◆ DONE%b %s\n" "$C_GREEN" "$C_RESET" "▰▰▰▰▰▰▰▰▰▰ 100%"
  else
    printf "\r%b◆ FAIL%b 见日志：%s\n" "$C_RED" "$C_RESET" "$log_file"
    tail -n 40 "$log_file" || true
    return "$code"
  fi
}

tcp_value() { sysctl -n "$1" 2>/dev/null || echo "unknown"; }

tcp_status_panel() {
  section "Speed Slayer · TCP 状态"
  printf "%b%-18s%b %s\n" "$C_CYAN" "Kernel" "$C_RESET" "$(uname -r)"
  printf "%b%-18s%b %s\n" "$C_CYAN" "XanMod" "$C_RESET" "$(is_xanmod_kernel && echo YES || echo NO)"
  printf "%b%-18s%b %s\n" "$C_CYAN" "Congestion" "$C_RESET" "$(tcp_value net.ipv4.tcp_congestion_control)"
  printf "%b%-18s%b %s\n" "$C_CYAN" "Qdisc" "$C_RESET" "$(tcp_value net.core.default_qdisc)"
  printf "%b%-18s%b %s\n" "$C_CYAN" "IPv6 disabled" "$C_RESET" "$(tcp_value net.ipv6.conf.all.disable_ipv6)"
}

tcp_plan_panel() {
  section "Speed Slayer · TCP 施工计划"
  if is_xanmod_kernel; then
    progress_step 10 "已在 XanMod 内核：跳过内核安装阶段"
    progress_step 35 "执行 BBR v3 / FQ 网络参数优化"
    progress_step 55 "执行 DNS 净化 / 网络稳定性修复"
    progress_step 75 "执行 Realm 首连超时修复"
    progress_step 90 "可选 IPv6 禁用"
    progress_step 100 "输出 TCP 状态摘要"
  else
    progress_step 10 "当前不是 XanMod：准备安装 XanMod + BBR v3 内核"
    progress_step 60 "安装完成后需要重启"
    progress_step 100 "重启后执行 speed 自动继续后续 TCP 调优 + Argo 安装"
  fi
}

detect_x64_level() {
  local flags level="1"
  flags="$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null || true)"
  if echo "$flags" | grep -qw 'avx512f'; then level="4"
  elif echo "$flags" | grep -qw 'avx2'; then level="3"
  elif echo "$flags" | grep -qw 'sse4_2'; then level="2"
  fi
  echo "$level"
}

xanmod_pkg_available() {
  local pkg="$1"
  apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/ {print $2; exit}' | grep -vqE '^(\(none\)|)$'
}

select_xanmod_pkg() {
  local level="$1" n pkg candidates=()
  for n in "$level" 3 2 1; do
    [ "$n" -gt "$level" ] 2>/dev/null && continue
    candidates+=("linux-xanmod-x64v${n}")
  done
  candidates+=("linux-xanmod")
  for pkg in "${candidates[@]}"; do
    if xanmod_pkg_available "$pkg"; then
      echo "$pkg"
      return 0
    fi
  done
  return 1
}

show_xanmod_candidates() {
  apt-cache search '^linux-xanmod' 2>/dev/null | awk '{print "  - "$1}' | sort -u | head -30 || true
}

native_install_xanmod_kernel() {
  section "Speed Slayer · 内核加速组件"
  if [ "$(uname -m)" != "x86_64" ]; then
    warn "当前架构暂未适配自动内核安装，将切换到兼容安装路径。"
    return 2
  fi
  if [ ! -r /etc/os-release ]; then
    err "无法识别系统：缺少 /etc/os-release"
    return 2
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ID:-}" != "debian" ] && [ "${ID:-}" != "ubuntu" ]; then
    warn "当前系统暂未适配自动内核安装，将切换到兼容安装路径。"
    return 2
  fi

  progress_step 10 "安装依赖：wget / gnupg / ca-certificates"
  apt-get update -y >>"$WORK_DIR/kernel-install.log" 2>&1 || true
  apt-get install -y wget gnupg ca-certificates >>"$WORK_DIR/kernel-install.log" 2>&1

  progress_step 25 "导入 XanMod GPG key"
  local keyring="/usr/share/keyrings/xanmod-archive-keyring.gpg"
  local key_tmp
  key_tmp="$(mktemp)"
  if ! wget -qO "$key_tmp" "https://dl.xanmod.org/archive.key" >>"$WORK_DIR/kernel-install.log" 2>&1; then
    err "XanMod GPG key 下载失败"
    rm -f "$key_tmp"
    return 1
  fi
  gpg --dearmor -o "$keyring" --yes < "$key_tmp" >>"$WORK_DIR/kernel-install.log" 2>&1
  rm -f "$key_tmp"

  progress_step 40 "写入临时 XanMod APT 源"
  local repo_file="/etc/apt/sources.list.d/xanmod-release.list"
  echo "deb [signed-by=${keyring}] https://deb.xanmod.org releases main" > "$repo_file"

  progress_step 55 "检测 CPU x86-64-v 等级"
  local level pkg install_ok=0
  level="$(detect_x64_level)"
  apt-get update -y >>"$WORK_DIR/kernel-install.log" 2>&1 || true
  if ! pkg="$(select_xanmod_pkg "$level")"; then
    err "未找到可安装的 XanMod 内核包。"
    echo "可用包候选："
    show_xanmod_candidates
    echo "日志：$WORK_DIR/kernel-install.log"
    return 1
  fi
  info "CPU 等级：x86-64-v${level}；选择内核包：${pkg}"

  progress_step 70 "安装 XanMod 内核包"
  if apt-get install -y "$pkg" >>"$WORK_DIR/kernel-install.log" 2>&1; then
    install_ok=1
  else
    warn "${pkg} 安装失败，尝试通用 XanMod 内核包。"
    if [ "$pkg" != "linux-xanmod" ] && xanmod_pkg_available "linux-xanmod" && apt-get install -y linux-xanmod >>"$WORK_DIR/kernel-install.log" 2>&1; then
      pkg="linux-xanmod"
      install_ok=1
    fi
  fi
  [ "$install_ok" -eq 1 ] || { err "XanMod 内核包安装失败，日志：$WORK_DIR/kernel-install.log"; return 1; }

  progress_step 88 "验证内核包安装"
  if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
    if ! dpkg -l 2>/dev/null | grep -qE '^ii\s+linux-(image|headers)-.*xanmod'; then
      err "内核包安装验证失败：${pkg}"
      echo "日志：$WORK_DIR/kernel-install.log"
      return 1
    fi
  fi

  progress_step 95 "清理临时 XanMod APT 源"
  rm -f "$repo_file"
  apt-get update -y >>"$WORK_DIR/kernel-install.log" 2>&1 || true

  progress_step 100 "XanMod 安装完成，重启后执行 speed 继续"
  return 0
}

run_tcp_backend_visible() {
  mkdir -p "$WORK_DIR"
  if [ "${SPEED_KERNEL_MODE:-native}" = "native" ]; then
    set +e
    native_install_xanmod_kernel
    local code=$?
    set -e
    if [ "$code" -eq 0 ]; then
      return 0
    elif [ "$code" -ne 2 ]; then
      return "$code"
    fi
  fi
  warn "正在切换到兼容安装路径。"
  fetch_or_run_script "$TCP_SCRIPT_LOCAL" "scripts/tcp-one-click-optimize.sh"
}

native_speed_tcp_tune() {
  local ipv6_choice="$1"
  section "Speed Slayer · TCP 加速配置"
  progress_step 20 "写入 sysctl 网络参数"
  cat > /etc/sysctl.d/99-speed-slayer-tcp.conf <<'EOF'
# Speed Slayer native TCP profile
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 4096
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.ip_local_port_range = 1024 65535
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5
EOF
  progress_step 40 "应用 sysctl 参数"
  sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-speed-slayer-tcp.conf >/dev/null 2>&1 || true

  progress_step 55 "应用网卡 FQ 队列"
  local dev
  for dev in $(ls /sys/class/net 2>/dev/null | grep -vE '^(lo|docker|veth|br-|virbr|tun|tap)'); do
    tc qdisc replace dev "$dev" root fq >/dev/null 2>&1 || true
  done

  progress_step 70 "优化文件描述符限制"
  if ! grep -q 'Speed Slayer file descriptor limits' /etc/security/limits.conf 2>/dev/null; then
    cat >> /etc/security/limits.conf <<'EOF'
# Speed Slayer file descriptor limits
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
  fi

  progress_step 82 "IPv6 策略"
  if [[ "$ipv6_choice" =~ ^[Yy]$ ]]; then
    cat > /etc/sysctl.d/99-speed-slayer-disable-ipv6.conf <<'EOF'
# Speed Slayer optional IPv6 disable
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    sysctl -p /etc/sysctl.d/99-speed-slayer-disable-ipv6.conf >/dev/null 2>&1 || true
  else
    rm -f /etc/sysctl.d/99-speed-slayer-disable-ipv6.conf
  fi

  progress_step 92 "验证 BBR / FQ 状态"
  echo "congestion=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  echo "qdisc=$(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"
  progress_step 100 "TCP 加速配置完成"
}

prepare_tcp_core_lib() {
  local src="$1" out
  out="$(mktemp /tmp/speed-slayer-tcp-core.XXXXXX.sh)"
  # 生成可加载的 TCP 函数库，避免启动交互菜单。
  sed '/^[[:space:]]*main[[:space:]]*"\$@"[[:space:]]*$/d' "$src" > "$out"
  bash -n "$out"
  echo "$out"
}

run_tcp_backend_silent() {
  local ipv6_choice="$1"
  if [ "${SPEED_TCP_MODE:-native}" = "native" ]; then
    native_speed_tcp_tune "$ipv6_choice"
    return 0
  fi

  local src core
  if [ -s "$TCP_CORE_LIB_LOCAL" ]; then
    core="$TCP_CORE_LIB_LOCAL"
  else
    if [ -s "$TCP_SCRIPT_LOCAL" ]; then
      src="$TCP_SCRIPT_LOCAL"
    else
      src="$(download_script "scripts/tcp-one-click-optimize.sh")"
    fi
    core="$(prepare_tcp_core_lib "$src")"
  fi
  # shellcheck disable=SC1090
  source "$core"
  AUTO_MODE=1
  echo "[15%] TCP 核心优化"
  bbr_configure_direct
  echo "[35%] DNS 与网络稳定性"
  dns_purify_and_harden
  echo "[55%] 首连稳定性修复"
  realm_fix_timeout
  if [[ "$ipv6_choice" =~ ^[Yy]$ ]]; then
    echo "[75%] IPv6 策略应用"
    disable_ipv6_permanent
  else
    echo "[75%] 跳过 IPv6 永久禁用"
  fi
  AUTO_MODE=""
}

run_tcp_optimize() {
  require_root
  render_header_once
  tcp_status_panel
  tcp_plan_panel
  warn "TCP 阶段会修改内核 / sysctl / DNS / IPv6 等系统网络配置，且可能要求重启。"
  if ! confirm_action "是否继续？默认回车 = Y"; then
    warn "已取消 TCP 优化。"
    return 0
  fi
  install_shortcut || true

  if ! is_xanmod_kernel; then
    save_pending_state
    section "安装 XanMod + BBR v3 内核"
    warn "当前不是 XanMod 内核。此阶段保留核心输出，避免隐藏安装失败或重启提示。"
    run_tcp_backend_visible
    show_continue_hint
    return 0
  fi

  local ipv6_choice="Y"
  if [ "${ASSUME_Y:-0}" != "1" ]; then
    printf "%b?%b TCP 调优最后是否永久禁用 IPv6？默认回车 = Y %b[Y/n]%b " "$C_YELLOW" "$C_RESET" "$C_GREEN" "$C_RESET"
    read -r ipv6_choice || ipv6_choice=""
    ipv6_choice="${ipv6_choice:-Y}"
  fi

  section "执行 TCP 网络调优"
  info "正在应用 Speed Slayer TCP 加速配置。"
  progress_step 15 "BBR v3 / FQ / TCP buffer 参数"
  progress_step 35 "DNS 净化与网络稳定性修复"
  progress_step 55 "Realm 首连超时修复"
  progress_step 75 "IPv6 策略：${ipv6_choice}"
  run_with_progress "Speed Slayer TCP 加速配置" "$WORK_DIR/tcp-optimize.log" run_tcp_backend_silent "$ipv6_choice"
  progress_step 100 "TCP 调优完成"
  tcp_status_panel || true
}

gen_uuid() {
  if [ -r /proc/sys/kernel/random/uuid ]; then
    cat /proc/sys/kernel/random/uuid
  elif command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr 'A-Z' 'a-z'
  else
    cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1 | sed -E 's/(.{8})(.{4})(.{4})(.{4})(.{12})/\1-\2-\3-\4-\5/'
  fi
}

shell_quote() { printf '%q' "$1"; }

write_argox_vmess_config() {
  require_root
  mkdir -p "$WORK_DIR"

  local uuid="${UUID:-}"
  local ws_path="${WS_PATH:-$DEFAULT_WS_PATH}"
  local start_port="${START_PORT:-$DEFAULT_START_PORT}"
  local nginx_port="${NGINX_PORT:-$DEFAULT_NGINX_PORT}"
  local node_name="${NODE_NAME:-$DEFAULT_NODE_NAME}"
  local argo_domain="${ARGO_DOMAIN:-}"
  local argo_auth="${ARGO_AUTH:-}"
  local server="${SERVER:-}"
  local server_port="${SERVER_PORT:-443}"

  [ -n "$uuid" ] || uuid="$(gen_uuid)"

  {
    echo '# Generated by Speed Slayer'
    echo '# Native VMess + WebSocket config. No ArgoX install chain.'
    echo 'INSTALL_PROTOCOLS=(f)'
    printf 'START_PORT=%s\n' "$start_port"
    printf 'VMESS_WS_PORT=%s\n' "$start_port"
    printf 'NGINX_PORT=%s\n' "$nginx_port"
    printf 'UUID=%s\n' "$(shell_quote "$uuid")"
    printf 'WS_PATH=%s\n' "$(shell_quote "$ws_path")"
    printf 'NODE_NAME=%s\n' "$(shell_quote "$node_name")"
    [ -n "$argo_domain" ] && printf 'ARGO_DOMAIN=%s\n' "$(shell_quote "$argo_domain")"
    [ -n "$argo_auth" ] && printf 'ARGO_AUTH=%s\n' "$(shell_quote "$argo_auth")"
    if [ -n "$server" ]; then
      printf 'SERVER=%s\n' "$(shell_quote "$server")"
      printf 'SERVER_PORT=%s\n' "$(shell_quote "$server_port")"
    fi
  } > "$CONFIG_FILE"

  chmod 600 "$CONFIG_FILE"
  success "已生成 VMess+WS 配置：$CONFIG_FILE"
  info "协议：VMess + WebSocket | Path：/${ws_path}-vm | Xray：${start_port} | Nginx：${nginx_port}"
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64|64" ;;
    aarch64|arm64) echo "arm64|arm64-v8a" ;;
    *) err "暂只支持 x86_64 / arm64：$(uname -m)"; return 1 ;;
  esac
}

install_base_deps() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y curl wget unzip nginx openssl ca-certificates iproute2 >/dev/null 2>&1
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget unzip nginx openssl ca-certificates iproute >/dev/null 2>&1
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget unzip nginx openssl ca-certificates iproute >/dev/null 2>&1
  else
    err "暂不支持当前系统包管理器"
    return 1
  fi
}

download_speed_binaries() {
  local archs cf_arch xray_arch tmp
  archs="$(detect_arch)"; cf_arch="${archs%%|*}"; xray_arch="${archs##*|}"
  mkdir -p /etc/argox /etc/argox/subscribe
  if [ ! -x /etc/argox/cloudflared ]; then
    curl -LfsS "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${cf_arch}" -o /etc/argox/cloudflared
    chmod +x /etc/argox/cloudflared
  fi
  if [ ! -x /etc/argox/xray ]; then
    tmp="$(mktemp -d)"
    curl -LfsS "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${xray_arch}.zip" -o "$tmp/xray.zip"
    unzip -qo "$tmp/xray.zip" -d "$tmp"
    mv "$tmp/xray" /etc/argox/xray
    [ -f "$tmp/geoip.dat" ] && mv "$tmp/geoip.dat" /etc/argox/geoip.dat || true
    [ -f "$tmp/geosite.dat" ] && mv "$tmp/geosite.dat" /etc/argox/geosite.dat || true
    chmod +x /etc/argox/xray
    rm -rf "$tmp"
  fi
}

load_speed_config() {
  [ -s "$CONFIG_FILE" ] && . "$CONFIG_FILE"
  UUID="${UUID:-$(gen_uuid)}"
  WS_PATH="${WS_PATH:-$DEFAULT_WS_PATH}"
  VMESS_WS_PORT="${VMESS_WS_PORT:-${START_PORT:-$DEFAULT_START_PORT}}"
  NGINX_PORT="${NGINX_PORT:-$DEFAULT_NGINX_PORT}"
  NODE_NAME="${NODE_NAME:-Speed-Slayer}"
}

write_native_xray_config() {
  cat > /etc/argox/inbound.json <<EOF
{"log":{"loglevel":"warning","access":"/etc/argox/xray-access.log","error":"/etc/argox/xray-error.log"},"inbounds":[{"tag":"${NODE_NAME} vmess-ws","listen":"127.0.0.1","port":${VMESS_WS_PORT},"protocol":"vmess","settings":{"clients":[{"id":"${UUID}","alterId":0}]},"streamSettings":{"network":"ws","wsSettings":{"path":"/${WS_PATH}-vm"}},"sniffing":{"enabled":true,"destOverride":["http","tls"]}}],"outbounds":[{"protocol":"freedom","tag":"direct"}]}
EOF
}

json_escape() { python3 -c 'import json,sys; print(json.dumps(sys.stdin.read().rstrip("\n"))[1:-1])'; }

make_vmess_url() {
  local host="$1" server="${SERVER:-www.visa.com}" port="${SERVER_PORT:-443}" payload
  payload=$(cat <<EOF
{"v":"2","ps":"$(printf '%s' "${NODE_NAME} vmess-ws" | json_escape)","add":"$(printf '%s' "$server" | json_escape)","port":"${port}","id":"${UUID}","aid":"0","scy":"none","net":"ws","type":"none","host":"$(printf '%s' "$host" | json_escape)","path":"/${WS_PATH}-vm","tls":"tls","sni":"$(printf '%s' "$host" | json_escape)","fp":"chrome"}
EOF
)
  printf 'vmess://%s\n' "$(printf '%s' "$payload" | base64 -w0)"
}

write_native_subscriptions() {
  local host="$1" vmess_url
  mkdir -p /etc/argox/subscribe
  vmess_url="$(make_vmess_url "$host")"
  printf '%s\n' "$vmess_url" > /etc/argox/vmess.txt
  printf '%s\n' "$vmess_url" | base64 -w0 > /etc/argox/subscribe/base64
  cat > /etc/argox/subscribe/clash <<EOF
proxies:
  - name: "${NODE_NAME} vmess-ws"
    type: vmess
    server: "${SERVER:-www.visa.com}"
    port: ${SERVER_PORT:-443}
    uuid: "${UUID}"
    alterId: 0
    cipher: none
    tls: true
    servername: "${host}"
    network: ws
    ws-opts:
      path: "/${WS_PATH}-vm"
      headers: { Host: "${host}" }
EOF
  cp /etc/argox/subscribe/base64 /etc/argox/subscribe/shadowrocket
  cat > /etc/argox/list <<EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Speed Slayer · VMess+WS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Protocol : VMess
Network  : WebSocket
UUID     : ${UUID}
Host/SNI : ${host}
Path     : /${WS_PATH}-vm
CDN      : ${SERVER:-www.visa.com}:${SERVER_PORT:-443}

VMess URL:
${vmess_url}

Subscriptions:
https://${host}/${UUID}/base64
https://${host}/${UUID}/clash
https://${host}/${UUID}/shadowrocket
https://${host}/${UUID}/auto
EOF
}

write_native_nginx_config() {
  cat > /etc/argox/nginx.conf <<EOF
worker_processes auto;
events { worker_connections 1024; }
http { server { listen 127.0.0.1:${NGINX_PORT}; server_name _;
location /${WS_PATH}-vm { proxy_pass http://127.0.0.1:${VMESS_WS_PORT}; proxy_http_version 1.1; proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_set_header Host \$host; }
location /${UUID}/base64 { alias /etc/argox/subscribe/base64; default_type text/plain; }
location /${UUID}/clash { alias /etc/argox/subscribe/clash; default_type text/plain; }
location /${UUID}/shadowrocket { alias /etc/argox/subscribe/shadowrocket; default_type text/plain; }
location /${UUID}/auto { alias /etc/argox/subscribe/base64; default_type text/plain; }
location / { return 200 'Speed Slayer OK'; }
} }
EOF
}

write_native_services() {
  cat > /etc/systemd/system/xray.service <<EOF
[Unit]
Description=Speed Slayer Xray VMess WS
After=network.target
[Service]
User=root
ExecStart=/etc/argox/xray run -c /etc/argox/inbound.json
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
  cat > /etc/systemd/system/argo.service <<EOF
[Unit]
Description=Speed Slayer Cloudflare Tunnel
After=network.target xray.service
[Service]
Type=simple
ExecStart=/etc/argox/cloudflared tunnel --edge-ip-version auto --no-autoupdate --url http://127.0.0.1:${NGINX_PORT} --metrics 127.0.0.1:0
Restart=on-failure
RestartSec=5
StandardOutput=append:/etc/argox/argo.log
StandardError=append:/etc/argox/argo.log
[Install]
WantedBy=multi-user.target
EOF
}

fetch_quick_tunnel_domain() {
  local domain i metrics
  for i in $(seq 1 45); do
    domain="$(grep -Eo 'https://[-a-zA-Z0-9.]+\.trycloudflare\.com' /etc/argox/argo.log 2>/dev/null | tail -n1 | sed 's#https://##' || true)"
    [ -n "$domain" ] && { echo "$domain"; return 0; }
    metrics="$(ss -lntp 2>/dev/null | awk '/cloudflared/ {print $4}' | awk -F: '{print $NF}' | tail -n1)"
    [ -n "$metrics" ] && domain="$(curl -fsS "http://127.0.0.1:${metrics}/quicktunnel" 2>/dev/null | awk -F'"' '{print $4}' || true)"
    [[ "${domain:-}" =~ trycloudflare\.com$ ]] && { echo "$domain"; return 0; }
    sleep 1
  done
  return 1
}

progress_step() {
  local pct="$1" msg="$2"
  printf "%b[%3s%%]%b %s\n" "$C_MAGENTA" "$pct" "$C_RESET" "$msg"
}

native_argo_install_staged() {
  section "Speed Slayer · Argo VMess+WS"
  load_speed_config
  progress_step 5 "安装前检查端口与残留"
  preflight_argo_ports
  progress_step 10 "安装基础依赖"
  install_base_deps >>"$LOG_FILE" 2>&1
  progress_step 25 "下载 / 校验 cloudflared 与 Xray-core"
  download_speed_binaries >>"$LOG_FILE" 2>&1
  progress_step 45 "写入纯 VMess+WS Xray 配置"
  write_native_xray_config >>"$LOG_FILE" 2>&1
  progress_step 55 "写入 Nginx WebSocket 反代与订阅接口"
  write_native_nginx_config >>"$LOG_FILE" 2>&1
  progress_step 65 "写入 systemd 服务"
  write_native_services >>"$LOG_FILE" 2>&1
  progress_step 75 "启动 Xray / Nginx / Cloudflared"
  systemctl daemon-reload >>"$LOG_FILE" 2>&1
  systemctl enable --now xray >>"$LOG_FILE" 2>&1
  nginx -t -c /etc/argox/nginx.conf >>"$LOG_FILE" 2>&1
  pkill -f 'nginx.*argox/nginx.conf' >>"$LOG_FILE" 2>&1 || true
  nginx -c /etc/argox/nginx.conf >>"$LOG_FILE" 2>&1
  : > /etc/argox/argo.log
  systemctl enable --now argo >>"$LOG_FILE" 2>&1
  progress_step 88 "获取 Argo 隧道域名"
  local host
  host="${ARGO_DOMAIN:-}"
  [ -n "$host" ] || host="$(fetch_quick_tunnel_domain)"
  [ -n "$host" ] || { err "未获取到 Argo 临时域名，查看 /etc/argox/argo.log"; return 1; }
  progress_step 96 "生成 VMess URL 与订阅文件"
  write_native_subscriptions "$host" >>"$LOG_FILE" 2>&1
  progress_step 100 "完成"
}

verify_vmess_only() {
  local inbound="/etc/argox/inbound.json"
  [ -s "$inbound" ] || { err "未找到 inbound 配置：$inbound"; return 1; }
  python3 - "$inbound" <<'PYVERIFY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
inbounds = data.get('inbounds') or []
if len(inbounds) != 1:
    print(f"inbound 数量异常：{len(inbounds)}", file=sys.stderr)
    sys.exit(1)
ib = inbounds[0]
if ib.get('protocol') != 'vmess':
    print(f"协议异常：{ib.get('protocol')}", file=sys.stderr)
    sys.exit(1)
stream = ib.get('streamSettings') or {}
if stream.get('network') != 'ws':
    print(f"传输异常：{stream.get('network')}", file=sys.stderr)
    sys.exit(1)
print('VMess+WS 校验通过')
PYVERIFY
}

extract_vmess_only() { [ -s /etc/argox/list ] && cat /etc/argox/list || warn "尚未生成 /etc/argox/list"; }

install_argo_vmess_ws() {
  render_header_once
  require_root
  clean_argo_state >/dev/null 2>&1 || true
  write_argox_vmess_config
  info "正在部署 Argo VMess+WS 节点。"
  info "安装前会自动清理旧服务、旧进程和旧配置，支持重复安装。"
  if ! native_argo_install_staged; then
    fail_report "Argo VMess+WS 部署"
    return 1
  fi
  if ! verify_vmess_only; then
    fail_report "VMess+WS 配置校验"
    return 1
  fi
  success "Argo VMess+WS 安装流程结束"
  extract_vmess_only || true
  summarize_result || true
  health_check || true
}

show_argo_vmess_ws_info() {
  require_root
  extract_vmess_only
}

uninstall_argo_vmess_ws() {
  render_header_once
  require_root
  warn "卸载 Speed Slayer Argo VMess+WS 服务"
  systemctl stop argo xray >/dev/null 2>&1 || true
  pkill -f 'nginx.*argox/nginx.conf' >/dev/null 2>&1 || true
  systemctl disable argo xray >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/argo.service /etc/systemd/system/xray.service
  systemctl daemon-reload >/dev/null 2>&1 || true
  rm -rf /etc/argox
  success "Speed Slayer Argo VMess+WS 已卸载"
}

clean_argo_state() {
  require_root
  warn "清理现有 Argo 配置并备份数据。"
  local ts
  ts="$(date +%Y%m%d%H%M%S)"
  systemctl stop argo xray >/dev/null 2>&1 || true
  systemctl disable argo xray >/dev/null 2>&1 || true
  pkill -f '/etc/argox/cloudflared' >/dev/null 2>&1 || true
  pkill -f '/etc/argox/xray' >/dev/null 2>&1 || true
  pkill -f 'nginx.*argox/nginx.conf' >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/argo.service /etc/systemd/system/xray.service
  systemctl daemon-reload >/dev/null 2>&1 || true
  if [ -d /etc/argox ]; then
    mv /etc/argox "/etc/argox.bak.${ts}" 2>/dev/null || rm -rf /etc/argox
  fi
  mkdir -p /etc/argox /etc/argox/subscribe
  success "Argo 配置已备份清理。"
}

force_all() {
  render_header_once
  ASSUME_Y=1
  install_shortcut || true
  if ! is_xanmod_kernel; then
    save_pending_state
    run_tcp_optimize
    return 0
  fi
  run_tcp_optimize
  install_argo_vmess_ws
  clear_state || true
}

run_all() {
  render_header_once
  warn "--all 是安全主页模式：不会自动执行 BBR；请选择菜单项后再确认。"
  menu_body
}

continue_after_reboot() {
  render_header_once
  require_root
  install_shortcut || true
  if ! is_xanmod_kernel; then
    err "当前仍未进入 XanMod 内核，暂停继续安装 Argo，避免循环。"
    echo "当前内核: $(uname -r)"
    echo "建议检查 VPS 是否支持自定义内核、GRUB 启动项或重新执行 speed --optimize。"
    exit 1
  fi
  info "检测到 XanMod 内核，继续执行 TCP 网络调优 + Argo VMess+WS"
  run_tcp_optimize
  install_argo_vmess_ws
  clear_state || true
}

check_environment() {
  require_root
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Speed Slayer · 环境检测"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "系统内核: $(uname -r)"
  echo "系统架构: $(uname -m)"
  echo "Root 权限: OK"
  for cmd in curl wget bash systemctl ss openssl; do
    if command -v "$cmd" >/dev/null 2>&1; then
      printf "%-12s: OK\n" "$cmd"
    else
      printf "%-12s: MISSING\n" "$cmd"
    fi
  done
  echo "TCP 拥塞控制: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  echo "默认队列算法: $(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"
  if [ -s /etc/argox/list ]; then
    echo "Speed Slayer 节点信息: FOUND /etc/argox/list"
  else
    echo "Speed Slayer 节点信息: NOT FOUND"
  fi
}

field_from_list() {
  local key="$1"
  awk -F: -v k="$key" '$1 ~ k {sub(/^[[:space:]]+/,"",$2); print $2; exit}' /etc/argox/list 2>/dev/null
}

subscription_url() {
  local name="$1"
  grep -E "https://.*/${name}$" /etc/argox/list 2>/dev/null | head -1
}

summarize_result() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Speed Slayer · Installation Complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  printf "%-11s %s\n" "Kernel" "$(uname -r)"
  printf "%-11s %s\n" "BBR" "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  printf "%-11s %s\n" "Queue" "$(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"

  if [ -s /etc/argox/list ]; then
    local uuid host path cdn vmess base64 clash shadowrocket auto
    uuid="$(field_from_list 'UUID')"
    host="$(field_from_list 'Host/SNI')"
    path="$(field_from_list 'Path')"
    cdn="$(field_from_list 'CDN')"
    vmess="$(grep -m1 '^vmess://' /etc/argox/list 2>/dev/null || true)"
    base64="$(subscription_url base64)"
    clash="$(subscription_url clash)"
    shadowrocket="$(subscription_url shadowrocket)"
    auto="$(subscription_url auto)"

    echo ""
    echo "Node"
    printf "%-11s %s\n" "Protocol" "VMess"
    printf "%-11s %s\n" "Network" "WebSocket"
    printf "%-11s %s\n" "TLS" "Enabled"
    printf "%-11s %s\n" "Host/SNI" "$host"
    printf "%-11s %s\n" "Path" "$path"
    printf "%-11s %s\n" "UUID" "$uuid"
    printf "%-11s %s\n" "CDN" "$cdn"

    echo ""
    echo "VMess URL"
    echo "$vmess"

    echo ""
    echo "Subscriptions"
    [ -n "$base64" ] && printf "%-13s %s\n" "Base64" "$base64"
    [ -n "$clash" ] && printf "%-13s %s\n" "Clash" "$clash"
    [ -n "$shadowrocket" ] && printf "%-13s %s\n" "Shadowrocket" "$shadowrocket"
    [ -n "$auto" ] && printf "%-13s %s\n" "Auto" "$auto"

    echo ""
    echo "Commands"
    echo "speed --doctor     # 全链路诊断"
    echo "speed --logs       # 查看日志"
    echo "speed --repair     # 清理并重装节点"
    echo ""
    echo "完整信息：/etc/argox/list"
  else
    echo ""
    echo "未检测到节点信息。"
    echo "如果刚完成内核安装，请重启后执行：speed"
    echo "如果需要单独部署节点，请执行：speed --install-argo-vmess"
  fi
}

service_state() {
  local svc="$1"
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
      echo "running"
    elif systemctl list-unit-files "$svc" >/dev/null 2>&1 || systemctl status "$svc" >/dev/null 2>&1; then
      echo "installed-but-not-running"
    else
      echo "not-found"
    fi
  else
    if pgrep -f "$svc" >/dev/null 2>&1; then
      echo "running"
    else
      echo "unknown"
    fi
  fi
}

port_state() {
  local port="$1"
  if command -v ss >/dev/null 2>&1 && ss -lnt 2>/dev/null | awk '{print $4}' | grep -Eq "(:|\\])${port}$"; then
    echo "listening"
  else
    echo "not-listening"
  fi
}

health_check() {
  require_root
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Speed Slayer · 健康检查"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  local fail=0
  local argo_state xray_state nginx_state nginx_port argo_domain
  argo_state="$(service_state argo)"
  xray_state="$(service_state xray)"
  nginx_state="$(service_state nginx)"
  nginx_port="$(awk -F= '/^NGINX_PORT=/{print $2}' "$CONFIG_FILE" 2>/dev/null | tr -d "'\"")"
  nginx_port="${nginx_port:-8001}"

  printf "%-18s %s\n" "argo.service:" "$argo_state"
  printf "%-18s %s\n" "xray.service:" "$xray_state"
  printf "%-18s %s\n" "nginx.service:" "$nginx_state"
  printf "%-18s %s (%s)\n" "本地入口端口:" "$nginx_port" "$(port_state "$nginx_port")"
  [ "$(port_state "$nginx_port")" != "listening" ] || echo "端口占用: $(port_owner "$nginx_port")"

  [ "$argo_state" = "running" ] || fail=1
  [ "$xray_state" = "running" ] || fail=1
  [ "$(port_state "$nginx_port")" = "listening" ] || fail=1

  if [ -s /etc/argox/list ]; then
    echo "节点列表: FOUND /etc/argox/list"
    argo_domain="$(grep -Eo 'https?://[^/ ]+' /etc/argox/list | sed 's#https\?://##' | grep -E 'trycloudflare\.com|cloudflare|\.' | head -n1 || true)"
    [ -n "$argo_domain" ] && echo "Argo 域名: $argo_domain" || echo "Argo 域名: 未能从节点列表提取"
  else
    echo "节点列表: MISSING /etc/argox/list"
    fail=1
  fi

  if [ -s /etc/argox/subscribe/base64 ]; then
    echo "Base64订阅: FOUND"
  else
    echo "Base64订阅: MISSING"
    fail=1
  fi

  echo ""
  if [ "$fail" -eq 0 ]; then
    success "健康检查通过：Argo / Xray / 本地入口 / 订阅文件均可用"
    return 0
  fi

  warn "健康检查未完全通过，建议按以下方向排查："
  [ "$argo_state" = "running" ] || echo "- Argo 未运行：执行 systemctl status argo 或重新运行 --install-argo-vmess"
  [ "$xray_state" = "running" ] || echo "- Xray 未运行：执行 systemctl status xray，检查 /etc/argox/xray.log"
  [ "$(port_state "$nginx_port")" = "listening" ] || echo "- 本地入口端口未监听：检查 nginx 配置或端口占用 ss -lntp | grep $nginx_port"
  [ -s /etc/argox/list ] || echo "- 节点列表未生成：查看 $LOG_FILE，确认 Argo 是否拿到隧道域名"
  [ -s /etc/argox/subscribe/base64 ] || echo "- 订阅文件缺失：重新执行 --show-url 或 --install-argo-vmess"
  return 1
}

remote_version() {
  local tmp
  tmp="$(mktemp /tmp/speed-slayer-version.XXXXXX)"
  if curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o "$tmp" 2>/dev/null; then
    grep -m1 '^SPEED_SLAYER_VERSION=' "$tmp" | cut -d= -f2- | tr -d '"'
  fi
  rm -f "$tmp"
}

check_self_update_hint() {
  [ "${SKIP_UPDATE_CHECK:-0}" = "1" ] && return 0
  [ -t 1 ] || return 0
  local rv
  rv="$(remote_version || true)"
  if [ -n "$rv" ] && [ "$rv" != "$SPEED_SLAYER_VERSION" ]; then
    warn "检测到新版本：${rv}（当前：${SPEED_SLAYER_VERSION}）。建议先执行：speed --update-self"
  fi
}

update_self() {
  require_root
  mkdir -p "$WORK_DIR"
  curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh?$(date +%s)" -o "$INSTALLED_BIN.tmp"
  bash -n "$INSTALLED_BIN.tmp"
  mv "$INSTALLED_BIN.tmp" "$INSTALLED_BIN"
  chmod +x "$INSTALLED_BIN"
  success "speed 已更新到最新版本：$INSTALLED_BIN"
  "$INSTALLED_BIN" --version || true
}

show_roadmap() {
  section "Speed Slayer · Roadmap"
  cat <<'EOF'
当前进度：约 88%

已完成：
- 一键完整流程与重启续跑
- BBR v3 / TCP 加速配置
- Argo VMess+WS 部署与订阅生成
- 重复安装预清理与 JSON 校验
- 日志菜单与修复命令
- 版本号与自更新
- 产品化文案清理

正在施工：
- 稳定性与失败提示收口
- 重复安装与残留处理继续加固
- 菜单结构产品化

下一步：
1. 收拢主页为二级菜单
2. 增强 doctor：端口、服务、配置、订阅全链路诊断
3. 输出最终安装摘要与复制友好节点信息
4. README / CHANGELOG / 发布版本收口

预计剩余：
- 可用 Beta：已接近，可进入实机回归
- 接近 V1.0：约 3 轮施工
EOF
}

show_logs() {
  require_root
  local target="${1:-menu}"
  case "$target" in
    kernel) tail -n 160 "$WORK_DIR/kernel-install.log" 2>/dev/null || warn "暂无内核安装日志" ;;
    tcp) tail -n 160 "$WORK_DIR/tcp-optimize.log" 2>/dev/null || warn "暂无 TCP 日志" ;;
    install) tail -n 160 "$LOG_FILE" 2>/dev/null || warn "暂无安装日志" ;;
    argo) tail -n 160 /etc/argox/argo.log 2>/dev/null || warn "暂无 Argo 日志" ;;
    xray) tail -n 160 /etc/argox/xray-error.log 2>/dev/null || warn "暂无 Xray 错误日志" ;;
    menu)
      section "Speed Slayer · 日志"
      echo "1. 安装总日志      $LOG_FILE"
      echo "2. 内核安装日志    $WORK_DIR/kernel-install.log"
      echo "3. TCP 调优日志    $WORK_DIR/tcp-optimize.log"
      echo "4. Argo 日志       /etc/argox/argo.log"
      echo "5. Xray 错误日志   /etc/argox/xray-error.log"
      echo "0. 返回"
      read -r -p "请选择: " log_choice
      case "$log_choice" in
        1) show_logs install ;;
        2) show_logs kernel ;;
        3) show_logs tcp ;;
        4) show_logs argo ;;
        5) show_logs xray ;;
        *) return 0 ;;
      esac
      ;;
    *) err "未知日志类型：$target"; return 1 ;;
  esac
}

repair_install() {
  require_root
  section "Speed Slayer · 修复"
  warn "将清理 Argo 服务/进程/配置残留，然后重新部署 VMess+WS。"
  if ! confirm_action "是否继续修复？默认回车 = Y"; then
    warn "已取消修复。"
    return 0
  fi
  clean_argo_state
  install_argo_vmess_ws
}

doctor_check() {
  local label="$1" cmd="$2" fix="${3:-}"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "%b[OK]%b   %s\n" "$C_GREEN" "$C_RESET" "$label"
  else
    printf "%b[FAIL]%b %s\n" "$C_RED" "$C_RESET" "$label"
    [ -n "$fix" ] && printf "       修复建议：%s\n" "$fix"
    return 1
  fi
}

doctor_warn() {
  local label="$1" cmd="$2" fix="${3:-}"
  if eval "$cmd" >/dev/null 2>&1; then
    printf "%b[OK]%b   %s\n" "$C_GREEN" "$C_RESET" "$label"
  else
    printf "%b[WARN]%b %s\n" "$C_YELLOW" "$C_RESET" "$label"
    [ -n "$fix" ] && printf "       建议：%s\n" "$fix"
  fi
}

doctor() {
  require_root
  section "Speed Slayer · Doctor"
  local failed=0
  doctor_check "Root 权限" '[ "$(id -u)" -eq 0 ]' "使用 root 执行 speed" || failed=1
  doctor_check "systemd 可用" 'command -v systemctl && [ -d /run/systemd/system ]' "当前系统可能不支持 systemd，建议使用 Debian/Ubuntu VPS" || failed=1
  doctor_check "curl 可用" 'command -v curl' "apt install -y curl" || failed=1
  doctor_check "ss 可用" 'command -v ss' "apt install -y iproute2" || failed=1
  doctor_check "python3 可用" 'command -v python3' "apt install -y python3" || failed=1

  echo ""
  echo "服务状态："
  doctor_warn "xray.service 运行" 'systemctl is-active --quiet xray' "执行 speed --repair"
  doctor_warn "argo.service 运行" 'systemctl is-active --quiet argo' "执行 speed --repair"
  doctor_warn "入口端口监听" '[ "$(port_state "${NGINX_PORT:-8001}")" = "listening" ]' "检查 nginx 或执行 speed --repair"
  doctor_warn "内部 WS 端口监听" '[ "$(port_state "${VMESS_WS_PORT:-30000}")" = "listening" ]' "检查 xray 或执行 speed --repair"

  echo ""
  echo "配置与订阅："
  doctor_check "inbound.json 存在" '[ -s /etc/argox/inbound.json ]' "执行 speed --install-argo-vmess" || failed=1
  if [ -s /etc/argox/inbound.json ]; then
    doctor_check "VMess+WS 配置有效" 'verify_vmess_only' "执行 speed --repair" || failed=1
  fi
  doctor_warn "节点信息已生成" '[ -s /etc/argox/list ]' "执行 speed --install-argo-vmess"
  doctor_warn "Base64 订阅存在" '[ -s /etc/argox/subscribe/base64 ]' "执行 speed --install-argo-vmess"

  echo ""
  echo "网络加速："
  doctor_warn "BBR 已启用" '[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" = "bbr" ]' "执行 speed --optimize"
  doctor_warn "队列算法 fq" '[ "$(sysctl -n net.core.default_qdisc 2>/dev/null)" = "fq" ]' "执行 speed --optimize"

  echo ""
  if [ "$failed" -eq 0 ]; then
    success "Doctor 完成：核心链路未发现阻断项。"
  else
    err "Doctor 完成：发现阻断项，建议优先执行 speed --repair 或查看 speed --logs。"
    return 1
  fi
}

usage() {
  cat <<'EOF'
Speed Slayer

Usage:
  bash vps-argo-vmess-oneclick.sh [command]

Commands:
  --tcp-status           查看 TCP / BBR / 内核状态
  --optimize             执行全自动 TCP 优化：BBR v3 + 网络调优
  --install-argo-vmess   安装/重装 Argo VMess + WS，并生成节点/订阅 URL
  --all                  显示交互主页（安全默认，不直接修改系统）
  --force-all            无人值守完整流程；如需重启，重启后执行 speed 即可继续
  --continue             重启后继续：TCP 网络调优 + Argo VMess + WS
  --show-url             查看已生成的节点/订阅信息
  --uninstall-argo       卸载 Argo VMess + WS 相关服务
  --clean-argo           清理现有 Argo 配置，备份 /etc/argox 后重装 VMess+WS
  --write-config         仅生成 Argo VMess + WS 配置文件，不安装
  --install-shortcut     安装 speed 快捷命令到 /usr/local/bin/speed
  --clear-state          清理续跑状态
  --check                检测当前环境和已安装状态
  --summary              输出结果摘要
  --health               安装后健康检查
  --doctor               一键诊断：环境检测 + 结果摘要 + 健康检查
  --logs [type]          查看日志：install/kernel/tcp/argo/xray
  --repair               清理残留并重装 Argo VMess+WS
  --roadmap              查看项目进度与下一步计划
  --update-self          更新 /usr/local/bin/speed 到 GitHub 最新版本
  --version              显示当前 Speed Slayer 版本
  -h, --help             显示帮助

Optional environment variables:
  UUID                   指定 VMess UUID，默认自动生成
  WS_PATH                指定 WS Path 前缀，默认 argox，实际 path 为 /<WS_PATH>-vm
  START_PORT             指定 Xray VMess 内部监听端口，默认 30000
  NGINX_PORT             指定 Nginx/Argo 本地入口端口，默认 8001
  NODE_NAME              指定节点名，默认 VPS-Argo-VMess
  ARGO_DOMAIN            固定 Argo 域名；不填则使用 trycloudflare 临时域名
  ARGO_AUTH              Argo Token / Json / Cloudflare API 信息；固定隧道时使用
  SERVER                 CDN 优选地址，默认 www.visa.com
  SERVER_PORT            优选 CDN 端口，默认 443

Examples:
  bash vps-argo-vmess-oneclick.sh --all
  WS_PATH=zaki NODE_NAME=Zaki-VPS bash vps-argo-vmess-oneclick.sh --install-argo-vmess
  ARGO_DOMAIN=tunnel.example.com ARGO_AUTH='eyJhIj...' bash vps-argo-vmess-oneclick.sh --install-argo-vmess
EOF
}

menu_section_node() {
  section "Speed Slayer · 节点管理"
  cat <<'EOF'
1. 安装/重装 Argo VMess+WS
2. 查看节点/订阅信息
3. 修复 Argo 安装
4. 卸载 Argo VMess+WS
5. 清理 Argo 配置
0. 返回主页
EOF
  read -r -p "请选择: " choice
  case "$choice" in
    1) install_argo_vmess_ws ;;
    2) show_argo_vmess_ws_info ;;
    3) repair_install ;;
    4) uninstall_argo_vmess_ws ;;
    5) clean_argo_state ;;
    0) menu_body ;;
    *) err "无效选择"; return 1 ;;
  esac
}

menu_section_tcp() {
  section "Speed Slayer · TCP 加速"
  cat <<'EOF'
1. 查看 TCP / BBR / 内核状态
2. 执行 TCP 优化
3. 重启后继续安装
0. 返回主页
EOF
  read -r -p "请选择: " choice
  case "$choice" in
    1) tcp_status_panel ;;
    2) run_tcp_optimize ;;
    3) continue_after_reboot ;;
    0) menu_body ;;
    *) err "无效选择"; return 1 ;;
  esac
}

menu_section_diag() {
  section "Speed Slayer · 诊断与日志"
  cat <<'EOF'
1. 一键诊断 doctor
2. 环境检测
3. 结果摘要
4. 健康检查
5. 查看日志
0. 返回主页
EOF
  read -r -p "请选择: " choice
  case "$choice" in
    1) doctor ;;
    2) check_environment ;;
    3) summarize_result ;;
    4) health_check ;;
    5) show_logs ;;
    0) menu_body ;;
    *) err "无效选择"; return 1 ;;
  esac
}

menu_section_system() {
  section "Speed Slayer · 更新与项目"
  cat <<'EOF'
1. 安装 speed 快捷命令
2. 更新 speed 自身
3. 项目进度 Roadmap
0. 返回主页
EOF
  read -r -p "请选择: " choice
  case "$choice" in
    1) install_shortcut ;;
    2) update_self ;;
    3) show_roadmap ;;
    0) menu_body ;;
    *) err "无效选择"; return 1 ;;
  esac
}

menu_body() {
  cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Speed Slayer · 控制台
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
介绍：BBR v3 网络优化 + Argo VMess WebSocket 节点生成
署名：NodeSeek @cshaizhihao
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 一键执行完整流程
2. 节点管理
3. TCP 加速
4. 诊断与日志
5. 修复与清理
6. 更新与项目进度
0. 退出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -r -p "请输入选择: " choice
  case "$choice" in
    1) force_all ;;
    2) menu_section_node ;;
    3) menu_section_tcp ;;
    4) menu_section_diag ;;
    5) repair_install ;;
    6) menu_section_system ;;
    0) exit 0 ;;
    *) err "无效选择"; exit 1 ;;
  esac
}

menu() {
  render_header_once
  menu_body
}

default_action() {
  render_header_once
  check_self_update_hint
  require_root
  if [ -s "$STATE_FILE" ]; then
    info "检测到续跑状态，自动继续完整流程。"
    continue_after_reboot
  else
    menu
  fi
}

case "${1:-}" in
  --tcp-status) tcp_status_panel ;;
  --optimize) run_tcp_optimize ;;
  --install-argo-vmess) install_argo_vmess_ws ;;
  --all) run_all ;;
  --force-all) force_all ;;
  --continue) continue_after_reboot ;;
  --show-url) show_argo_vmess_ws_info ;;
  --uninstall-argo) uninstall_argo_vmess_ws ;;
  --clean-argo) clean_argo_state ;;
  --write-config) write_argox_vmess_config ;;
  --install-shortcut) install_shortcut ;;
  --clear-state) clear_state ;;
  --check) check_environment ;;
  --summary) summarize_result ;;
  --health) health_check ;;
  --doctor) doctor ;;
  --logs) show_logs "${2:-menu}" ;;
  --repair) repair_install ;;
  --roadmap) show_roadmap ;;
  --update-self) update_self ;;
  --version) echo "Speed Slayer ${SPEED_SLAYER_VERSION}" ;;
  -h|--help) usage ;;
  "") default_action ;;
  *) err "未知参数：$1"; usage; exit 1 ;;
esac
