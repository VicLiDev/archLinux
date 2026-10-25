#!/usr/bin/env bash
#
# 安装完整的 Hyprland 桌面环境：
#
#   - Hyprland 合成器、portal、锁屏、空闲、壁纸、取色、uwsm
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

WALLPAPER_DIR="${HOME}/Pictures/wallpapers"

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

# Hyprland 专属组件
HYPRLAND_PKGS=(
  hyprland
  xdg-desktop-portal-hyprland
  uwsm
  hyprlock
  hypridle
  hyprpaper
  hyprpicker
)

function download_wallpapers()
{
  local index name target id
  local names=(
    01-alpine-lake.jpg
    02-forest-sunlight.jpg
    03-foggy-mountains.jpg
    04-mountain-peak.jpg
    05-valley.jpg
    06-green-hills.jpg
    07-snow-mountain.jpg
    08-forest-path.jpg
  )
  local ids=(
    photo-1501785888041-af3ef285b470
    photo-1441974231531-c6227db76b6e
    photo-1470071459604-3b5ec3a7fe05
    photo-1464822759023-fed622ff2c3b
    photo-1469474968028-56623f02e42e
    photo-1472214103451-9374bd1c798e
    photo-1500534623283-312aade485b7
    photo-1447752875215-b2761acb3c5d
  )

  mkdir -p -- "${WALLPAPER_DIR}"

  for index in "${!names[@]}"; do
    name="${names[${index}]}"
    target="${WALLPAPER_DIR}/${name}"

    if [[ -s "${target}" ]]; then
      log "Wallpaper already exists: ${name}"
      continue
    fi

    id="${ids[${index}]}"
    log "Downloading wallpaper: ${name}"
    if ! curl -L --fail --silent --show-error --retry 1 --max-time 120 \
        -o "${target}" \
        "https://images.unsplash.com/${id}?w=2560&q=85&fm=jpg&fit=crop"; then
      log_warn "failed to download wallpaper: ${name}"
      rm -f -- "${target}"
    fi
  done

  if [[ -s "${WALLPAPER_DIR}/01-alpine-lake.jpg" ]] \
      && [[ ! -e "${WALLPAPER_DIR}/cur_bkgrd.jpg" ]] \
      && [[ ! -L "${WALLPAPER_DIR}/cur_bkgrd.jpg" ]]; then
    ln -s -- "01-alpine-lake.jpg" "${WALLPAPER_DIR}/cur_bkgrd.jpg"
    log "Created wallpaper symlink: cur_bkgrd.jpg -> 01-alpine-lake.jpg"
  fi
}

function usage()
{
  cat <<'EOF'
Usage: ./ins_hpld_env.sh [options]

Install the complete Hyprland desktop stack, then enable and start SDDM.
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
  require_command curl

  # 先刷新 sudo 时间戳，后面的 pacman 和 systemctl 不再反复询问密码
  if ! sudo -v; then
    log_fail "sudo authentication failed"
    return 1
  fi

  log "Installing Hyprland desktop packages..."
  if ! sudo pacman -S --needed --noconfirm \
      "${COMMON_PKGS[@]}" "${HYPRLAND_PKGS[@]}"; then
    log_fail "failed to install Hyprland desktop packages"
    return 1
  fi
  log_pass "Hyprland desktop packages installed."

  download_wallpapers

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

  log_pass "SDDM is active. Select Hyprland in the session menu."
}

main "${@}"
