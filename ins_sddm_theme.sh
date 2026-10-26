#!/usr/bin/env bash
#
# 安装并配置 SDDM 的 Catppuccin Mocha 登录主题：
#
#   - 安装 Qt5 的 Quick Controls 和 SVG 运行库
#   - 下载 Catppuccin SDDM Mocha Blue 主题
#   - 使用深色的 08-forest-path.jpg 作为登录背景
#   - 写入 /etc/sddm.conf.d/20-catppuccin-theme.conf
#
# 以普通用户运行，脚本内部使用 sudo。主题写入系统目录后，
# 需要注销或重启才会在 SDDM 登录界面看到效果。

# -e：任何命令以非 0 退出时立即终止脚本
# -u：引用未定义变量时报错
# -o pipefail：管道中任意一段失败就视为整条管道失败
set -euo pipefail

LOG_LIB="${HOME}/bin/_log.sh"
if [[ ! -r "${LOG_LIB}" ]]; then
  printf 'Error: logging library not found: %s\n' "${LOG_LIB}" >&2
  exit 1
fi
source "${LOG_LIB}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_NAME="catppuccin-mocha-blue"
THEME_VERSION="v1.1.2"
THEME_URL="https://github.com/catppuccin/sddm/releases/download/${THEME_VERSION}/${THEME_NAME}-sddm.zip"
THEME_DIR="/usr/share/sddm/themes/${THEME_NAME}"
THEME_CONFIG_SRC="${SCRIPT_DIR}/cfg_sddm/theme.conf"
LOGIN_WALLPAPER="${HOME}/Pictures/wallpapers/08-forest-path.jpg"
SDDM_CONFIG_DIR="/etc/sddm.conf.d"
SDDM_CONFIG="${SDDM_CONFIG_DIR}/20-catppuccin-theme.conf"

function usage()
{
  cat <<'EOF'
Usage: ./ins_sddm_theme.sh [options]

Install the Catppuccin Mocha SDDM theme with a dark nature background.
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

function install_dependencies()
{
  log "Installing SDDM Qt5 theme dependencies..."
  if ! sudo pacman -S --needed --noconfirm \
      qt5-quickcontrols2 \
      qt5-svg; then
    log_fail "failed to install SDDM Qt5 theme dependencies"
    exit 1
  fi
  log_pass "SDDM Qt5 theme dependencies installed."
}

function download_theme()
{
  local temp_dir="${1}"

  log "Downloading ${THEME_NAME}..."
  if ! curl -L --fail --silent --show-error --retry 2 \
      -o "${temp_dir}/${THEME_NAME}.zip" \
      "${THEME_URL}"; then
    log_fail "failed to download ${THEME_NAME}"
    exit 1
  fi

  if ! bsdtar -xf "${temp_dir}/${THEME_NAME}.zip" -C "${temp_dir}"; then
    log_fail "failed to extract ${THEME_NAME}"
    exit 1
  fi

  if [[ ! -d "${temp_dir}/${THEME_NAME}" ]]; then
    log_fail "theme archive did not contain ${THEME_NAME}"
    exit 1
  fi
}

function install_theme()
{
  local temp_dir

  temp_dir="$(mktemp -d)"
  download_theme "${temp_dir}"

  log "Installing ${THEME_NAME} to ${THEME_DIR}..."
  if ! sudo install -d "${THEME_DIR}"; then
    rm -rf -- "${temp_dir}"
    log_fail "failed to create ${THEME_DIR}"
    exit 1
  fi

  if ! sudo cp -a "${temp_dir}/${THEME_NAME}/." "${THEME_DIR}/"; then
    rm -rf -- "${temp_dir}"
    log_fail "failed to copy ${THEME_NAME} files"
    exit 1
  fi

  rm -rf -- "${temp_dir}"
  log_pass "${THEME_NAME} installed."
}

function install_config()
{
  if [[ ! -f "${THEME_CONFIG_SRC}" ]]; then
    log_fail "theme config not found: ${THEME_CONFIG_SRC}"
    exit 1
  fi

  if [[ ! -s "${LOGIN_WALLPAPER}" ]]; then
    log_fail "login wallpaper not found: ${LOGIN_WALLPAPER}"
    exit 1
  fi

  log "Installing theme config and login wallpaper..."
  if ! sudo install -d "${THEME_DIR}/backgrounds"; then
    log_fail "failed to create theme backgrounds directory"
    exit 1
  fi

  if ! sudo install -m 644 \
      "${THEME_CONFIG_SRC}" \
      "${THEME_DIR}/theme.conf"; then
    log_fail "failed to install theme config"
    exit 1
  fi

  if ! sudo install -m 644 \
      "${LOGIN_WALLPAPER}" \
      "${THEME_DIR}/backgrounds/cur_bkgrd.jpg"; then
    log_fail "failed to install login wallpaper"
    exit 1
  fi

  if ! sudo install -d "${SDDM_CONFIG_DIR}"; then
    log_fail "failed to create ${SDDM_CONFIG_DIR}"
    exit 1
  fi

  if ! printf '[Theme]\nCurrent=%s\n' "${THEME_NAME}" \
      | sudo tee "${SDDM_CONFIG}" >/dev/null; then
    log_fail "failed to write ${SDDM_CONFIG}"
    exit 1
  fi

  log_pass "SDDM theme configured. Log out or reboot to see it."
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

  if (( EUID == 0 )); then
    log_fail "run this script as a normal user, not root"
    return 1
  fi

  require_command sudo
  require_command pacman
  require_command curl
  require_command bsdtar

  if ! sudo -v; then
    log_fail "sudo authentication failed"
    return 1
  fi

  install_dependencies
  install_theme
  install_config
}

main "${@}"
