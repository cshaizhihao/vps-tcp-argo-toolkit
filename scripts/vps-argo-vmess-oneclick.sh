#!/usr/bin/env bash
set -euo pipefail

# Speed Slayer
# Native Speed Slayer installer.
# - TCP optimize: uses the preserved TCP menu-66 entry.
# - Argo VMess+WS: native cloudflared + Xray + Nginx implementation, no ArgoX install chain.

REPO_RAW_BASE="https://raw.githubusercontent.com/cshaizhihao/speed-slayer/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd 2>/dev/null || echo .)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd 2>/dev/null || echo .)"

TCP_SCRIPT_LOCAL="${SCRIPT_DIR}/tcp-one-click-optimize.sh"

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
  printf "%b%s%b\n" "$C_WHITE" "  功能：BBR v3 / XanMod 网络调优 + 原生 Cloudflare Argo VMess WebSocket 节点生成。" "$C_RESET"
  printf "%b%s%b\n" "$C_DIM" "  Author: NodeSeek @cshaizhihao" "$C_RESET"
  echo ""
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
    cp "${BASH_SOURCE[0]}" "$INSTALLED_BIN"
  else
    curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh" -o "$INSTALLED_BIN"
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
    printf "\r${C_CYAN}◆ RUN ${C_RESET}%s" "${frames[$((i % ${#frames[@]}))]}"
    i=$((i + 1))
    sleep 1
  done
  set +e
  wait "$pid"
  local code=$?
  set -e
  if [ "$code" -eq 0 ]; then
    printf "\r${C_GREEN}◆ DONE${C_RESET} ▰▰▰▰▰▰▰▰▰▰ 100%\n"
  else
    printf "\r${C_RED}◆ FAIL${C_RESET} 见日志：%s\n" "$log_file"
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

run_tcp_backend_visible() {
  fetch_or_run_script "$TCP_SCRIPT_LOCAL" "scripts/tcp-one-click-optimize.sh"
}

prepare_tcp_core_lib() {
  local src="$1" out
  out="$(mktemp /tmp/speed-slayer-tcp-core.XXXXXX.sh)"
  # 删除上游脚本最后的 main "$@"，只加载函数，不启动菜单。
  sed '/^[[:space:]]*main[[:space:]]*"\$@"[[:space:]]*$/d' "$src" > "$out"
  bash -n "$out"
  echo "$out"
}

run_tcp_backend_silent() {
  local ipv6_choice="$1"
  local src core
  if [ -s "$TCP_SCRIPT_LOCAL" ]; then
    src="$TCP_SCRIPT_LOCAL"
  else
    src="$(download_script "scripts/tcp-one-click-optimize.sh")"
  fi
  core="$(prepare_tcp_core_lib "$src")"
  # shellcheck disable=SC1090
  source "$core"
  AUTO_MODE=1
  echo "[15%] 调用 bbr_configure_direct"
  bbr_configure_direct
  echo "[35%] 调用 dns_purify_and_harden"
  dns_purify_and_harden
  echo "[55%] 调用 realm_fix_timeout"
  realm_fix_timeout
  if [[ "$ipv6_choice" =~ ^[Yy]$ ]]; then
    echo "[75%] 调用 disable_ipv6_permanent"
    disable_ipv6_permanent
  else
    echo "[75%] 跳过 IPv6 永久禁用"
  fi
  AUTO_MODE=""
}

run_tcp_optimize() {
  require_root
  banner
  intro
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
  progress_step 15 "BBR v3 / FQ / TCP buffer 参数"
  progress_step 35 "DNS 净化与网络稳定性修复"
  progress_step 55 "Realm 首连超时修复"
  progress_step 75 "IPv6 策略：${ipv6_choice}"
  run_with_progress "Speed Slayer TCP 核心函数调优" "$WORK_DIR/tcp-optimize.log" run_tcp_backend_silent "$ipv6_choice"
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
  success "已生成原生 VMess+WS 配置：$CONFIG_FILE"
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
  section "原生安装 Argo VMess+WS"
  load_speed_config
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
  if grep -Eqi 'reality|hysteria|trojan|shadowsocks|vless|xhttp|grpc|ss-ws|trojan-ws|vless-ws' "$inbound"; then
    err "检测到非 VMess+WS 协议残留，拒绝标记为成功。"
    return 1
  fi
  grep -Eq '"protocol"[[:space:]]*:[[:space:]]*"vmess"' "$inbound"
  grep -Eq '"network"[[:space:]]*:[[:space:]]*"ws"' "$inbound"
}

extract_vmess_only() { [ -s /etc/argox/list ] && cat /etc/argox/list || warn "尚未生成 /etc/argox/list"; }

install_argo_vmess_ws() {
  banner
  require_root
  clean_argo_state >/dev/null 2>&1 || true
  write_argox_vmess_config
  info "启动原生 Argo VMess+WS 安装（不再调用 ArgoX 全家桶）"
  native_argo_install_staged
  verify_vmess_only
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
  banner
  require_root
  warn "卸载 Speed Slayer 原生 Argo VMess+WS 服务"
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
  warn "清理旧 Argo/全家桶残留，用于恢复到 Speed Slayer 原生 VMess+WS。"
  systemctl stop argo xray nginx >/dev/null 2>&1 || true
  systemctl disable argo xray >/dev/null 2>&1 || true
  rm -f /etc/systemd/system/argo.service /etc/systemd/system/xray.service
  systemctl daemon-reload >/dev/null 2>&1 || true
  mv /etc/argox "/etc/argox.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  success "旧 Argo 残留已备份清理；现在可执行：speed --install-argo-vmess"
}

force_all() {
  banner
  intro
  ASSUME_Y=1
  install_shortcut || true
  if ! is_xanmod_kernel; then
    save_pending_state
    run_tcp_optimize
    show_continue_hint
    return 0
  fi
  run_tcp_optimize
  install_argo_vmess_ws
  clear_state || true
}

run_all() {
  banner
  intro
  warn "--all 是安全主页模式：不会自动执行 BBR；请选择菜单项后再确认。"
  menu_body
}

continue_after_reboot() {
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

summarize_result() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " Speed Slayer · 结果摘要"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "内核: $(uname -r)"
  echo "拥塞控制: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo unknown)"
  echo "队列算法: $(sysctl -n net.core.default_qdisc 2>/dev/null || echo unknown)"
  if [ -s /etc/argox/list ]; then
    echo ""
    echo "Argo VMess+WS 节点/订阅信息已生成："
    grep -E 'vmess://|https?://.*/(base64|auto|clash|shadowrocket)|trycloudflare\.com|Index:|V2rayN|Nekoray' /etc/argox/list || true
    echo ""
    echo "完整信息：/etc/argox/list"
  else
    echo ""
    echo "未检测到 /etc/argox/list；如果刚完成 TCP 内核安装并重启，请重启后执行 --install-argo-vmess。"
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

update_self() {
  require_root
  mkdir -p "$WORK_DIR"
  curl -fsSL "${REPO_RAW_BASE}/scripts/vps-argo-vmess-oneclick.sh" -o "$INSTALLED_BIN.tmp"
  bash -n "$INSTALLED_BIN.tmp"
  mv "$INSTALLED_BIN.tmp" "$INSTALLED_BIN"
  chmod +x "$INSTALLED_BIN"
  success "speed 已更新到最新版本：$INSTALLED_BIN"
}

doctor() {
  require_root
  check_environment || true
  summarize_result || true
  health_check || true
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
  --continue             重启后继续：TCP 网络调优 + Argo VMess + WS（兼容旧用法）
  --show-url             查看已生成的节点/订阅信息
  --uninstall-argo       卸载 Argo VMess + WS 相关服务
  --clean-argo           清理旧 Argo 残留，备份 /etc/argox 后重装纯 VMess+WS
  --write-config         仅生成 Argo VMess + WS 配置文件，不安装
  --install-shortcut     安装 speed 快捷命令到 /usr/local/bin/speed
  --clear-state          清理续跑状态
  --check                检测当前环境和已安装状态
  --summary              输出结果摘要
  --health               安装后健康检查
  --doctor               一键诊断：环境检测 + 结果摘要 + 健康检查
  --update-self          更新 /usr/local/bin/speed 到 GitHub 最新版本
  -h, --help             显示帮助

Optional environment variables:
  UUID                   指定 VMess UUID，默认自动生成
  WS_PATH                指定 WS Path 前缀，默认 argox，实际 path 为 /<WS_PATH>-vm
  START_PORT             指定 Xray VMess 内部监听端口，默认 30000
  NGINX_PORT             指定 Nginx/Argo 本地入口端口，默认 8001
  NODE_NAME              指定节点名，默认 VPS-Argo-VMess
  ARGO_DOMAIN            固定 Argo 域名；不填则使用 trycloudflare 临时域名
  ARGO_AUTH              Argo Token / Json / Cloudflare API 信息；固定隧道时使用
  SERVER                 优选 CDN 地址，默认 www.visa.com
  SERVER_PORT            优选 CDN 端口，默认 443

Examples:
  bash vps-argo-vmess-oneclick.sh --all
  WS_PATH=zaki NODE_NAME=Zaki-VPS bash vps-argo-vmess-oneclick.sh --install-argo-vmess
  ARGO_DOMAIN=tunnel.example.com ARGO_AUTH='eyJhIj...' bash vps-argo-vmess-oneclick.sh --install-argo-vmess
EOF
}

menu_body() {
  cat <<'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Speed Slayer · 主页
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
介绍：BBR v3 / XanMod 网络调优 + 原生 Argo VMess WebSocket 节点生成
署名：NodeSeek @cshaizhihao
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. 查看 TCP / BBR / 内核状态
2. 执行 TCP 优化（进入前需 Y/N 确认，默认 Y）
3. 安装/重装 Argo VMess + WS
4. 一键执行完整流程（TCP 优化 + Argo VMess + WS）
5. 查看节点/订阅信息
6. 卸载 Argo VMess + WS
7. 清理旧 Argo 残留
8. 安装 speed 快捷命令
9. 重启后继续安装
10. 环境检测
11. 结果摘要
12. 健康检查
13. 一键诊断 doctor
14. 更新 speed 自身
0. 退出
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -r -p "请输入选择: " choice
  case "$choice" in
    1) tcp_status_panel ;;
    2) run_tcp_optimize ;;
    3) install_argo_vmess_ws ;;
    4) force_all ;;
    5) show_argo_vmess_ws_info ;;
    6) uninstall_argo_vmess_ws ;;
    7) clean_argo_state ;;
    8) install_shortcut ;;
    9) continue_after_reboot ;;
    10) check_environment ;;
    11) summarize_result ;;
    12) health_check ;;
    13) doctor ;;
    14) update_self ;;
    0) exit 0 ;;
    *) err "无效选择"; exit 1 ;;
  esac
}

menu() {
  banner
  intro
  menu_body
}

default_action() {
  banner
  intro
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
  --update-self) update_self ;;
  -h|--help) usage ;;
  "") default_action ;;
  *) err "未知参数：$1"; usage; exit 1 ;;
esac
