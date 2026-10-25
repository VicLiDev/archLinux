#!/usr/bin/env bash
#
# 安装完整的 niri 桌面环境：
#
#   - niri 合成器、XWayland、portal、锁屏、空闲、壁纸
#   - 终端、shell、状态栏、通知、启动器
#   - 截图、剪贴板、音频、网络、蓝牙、字体、输入法
#   - 显示管理器 SDDM
#
# 安装完成后会启用并启动 SDDM。以普通用户运行，脚本内部使用 sudo。
# 重复执行是安全的：pacman 只安装尚未安装的包。

# -e：任何命令以非 0 退出时立即终止脚本，避免错误被后续步骤掩盖
# -u：引用未定义变量时报错，防止变量名拼错后变成空字符串继续执行
# -o pipefail：管道中任意一段失败就视为整条管道失败（默认只看最后一段）
set -euo pipefail

# 复用通用日志库：log_out / log_warn / log_fail 等由 ~/bin/_log.sh 提供
LOG_LIB="${HOME}/bin/_log.sh"
if [[ ! -r "${LOG_LIB}" ]]; then
  printf 'Error: logging library not found: %s\n' "${LOG_LIB}" >&2
  exit 1
fi
source "${LOG_LIB}"

# 两套桌面共用的桌面基础软件
COMMON_PKGS=(
  # 终端、shell 与常用命令行工具
  kitty
  foot
  tmux
  less
  man-db
  zsh
  starship
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  fzf
  eza
  bat
  zoxide

  # 状态栏、通知、启动器
  waybar
  mako
  fuzzel

  # 文件管理器与桌面集成
  dolphin
  thunar
  thunar-volman
  gvfs
  gvfs-mtp
  udisks2
  tumbler
  ffmpegthumbnailer
  file-roller

  # 截图、剪贴板、亮度、媒体控制
  grim
  slurp
  swappy
  wl-clipboard
  cliphist
  brightnessctl
  playerctl

  # 音频
  pipewire
  pipewire-pulse
  pipewire-alsa
  wireplumber

  # 网络与蓝牙
  networkmanager
  bluez
  bluez-utils

  # 中文字体、等宽字体与输入法
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  ttf-firacode-nerd
  fcitx5
  fcitx5-chinese-addons
  fcitx5-gtk
  fcitx5-qt
  fcitx5-configtool

  # 认证、portal、Qt 与显示管理器
  polkit-gnome
  xdg-desktop-portal-gtk
  xdg-utils
  qt5-wayland
  qt6-wayland
  sddm
)

# niri 专属组件
NIRI_PKGS=(
  niri
  xwayland-satellite
  xdg-desktop-portal-wlr
  swaybg
  swaylock
  swayidle
)

function usage()
{
  cat <<'EOF'
Usage: ./ins_niri_env.sh [options]

Install the complete niri desktop stack, then enable and start SDDM.
Run this script as a normal user; sudo is used internally.

Options:
  -h, --help      Show this help
EOF
}

function require_command()
{
  local command_name="${1}"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    log_fail "required command not found: ${command_name}"
    exit 1
  fi
}

function main()
{
  local arg

  for arg in "${@}"; do
    case "${arg}" in
      -h|--help)
        usage
        return 0
        ;;
      *)
        log_fail "unknown option: ${arg}"
        usage
        return 1
        ;;
    esac
  done

  # 统一用普通用户执行，内部再调用 sudo，避免把配置写进 /root
  if (( EUID == 0 )); then
    log_fail "run this script as a normal user, not root"
    return 1
  fi

  require_command sudo
  require_command pacman
  require_command systemctl

  # 先刷新 sudo 时间戳，后面的 pacman 和 systemctl 不再反复询问密码
  if ! sudo -v; then
    log_fail "sudo authentication failed"
    return 1
  fi

  log "Installing niri desktop packages..."
  if ! sudo pacman -S --needed --noconfirm \
      "${COMMON_PKGS[@]}" "${NIRI_PKGS[@]}"; then
    log_fail "failed to install niri desktop packages"
    return 1
  fi
  log_pass "niri desktop packages installed."

  log "Setting graphical.target as the default boot target..."
  if ! sudo systemctl set-default graphical.target; then
    log_fail "failed to set graphical.target"
    return 1
  fi

  log "Enabling and starting SDDM..."
  if ! sudo systemctl enable --now sddm; then
    log_fail "failed to enable or start SDDM"
    return 1
  fi

  if ! systemctl is-active --quiet sddm; then
    log_fail "SDDM is not active; check: journalctl -b -u sddm"
    return 1
  fi

  log_pass "SDDM is active. Select niri in the session menu."
}

main "${@}"
