#!/usr/bin/env bash
#
# 把本仓库里的桌面配置链接到用户目录：
#
#   ~/.config/hypr -> <仓库>/cfg_hyprland
#   ~/.config/niri -> <仓库>/cfg_niri
#   ~/.config/waybar -> <仓库>/cfg_waybar
#   ~/.config/Thunar -> <仓库>/cfg_thunar
#   ~/.config/dolphinrc -> <仓库>/cfg_dolphin/dolphinrc
#   ~/.local/share/kio/servicemenus/open-terminal.desktop
#                       -> <仓库>/cfg_dolphin/open-terminal.desktop
#   ~/.config/kitty -> <仓库>/cfg_kitty
#   ~/.config/bat -> <仓库>/cfg_bat
#   ~/.config/starship.toml -> <仓库>/cfg_starship.toml
#   ~/.config/environment.d/10-fcitx5.conf -> <仓库>/cfg_environment.d/10-fcitx5.conf
#   ~/.config/fcitx5/profile -> <仓库>/cfg_fcitx5/profile
#   ~/.config/fcitx5/conf/classicui.conf -> <仓库>/cfg_fcitx5/conf/classicui.conf
#   ~/.config/fcitx5/conf/pinyin.conf -> <仓库>/cfg_fcitx5/conf/pinyin.conf
#   ~/.local/share/fcitx5/themes/Alpha-black
#                       -> <仓库>/cfg_fcitx5/themes/Alpha-black
#   ~/.zshrc -> <仓库>/cfg_zshrc
#
# 之后所有修改都直接改仓库里的文件，各程序看到的永远是同一份。
# 重复执行是安全的：已指向本仓库的软链会原样保留。

# -e：任何命令以非 0 退出时立即终止脚本，避免错误被后续步骤掩盖
# -u：引用未定义变量时报错，防止变量名拼错后变成空字符串继续执行
# -o pipefail：管道中任意一段失败就视为整条管道失败（默认只看最后一段）
# 合起来写成 -euo pipefail，等价于 set -e; set -u; set -o pipefail
set -euo pipefail

# 复用通用日志库：log_out / log_warn / log_fail 等由 ~/bin/_log.sh 提供
LOG_LIB="${HOME}/bin/_log.sh"
if [[ ! -r "${LOG_LIB}" ]]; then
  printf 'Error: logging library not found: %s\n' "${LOG_LIB}" >&2
  exit 1
fi
source "${LOG_LIB}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}"

# 仓库路径:目标名，链接到 ${CONFIG_DIR}
CONFIG_LINKS=(
  "cfg_hyprland:hypr"
  "cfg_niri:niri"
  "cfg_waybar:waybar"
  "cfg_thunar:Thunar"
  "cfg_dolphin/dolphinrc:dolphinrc"
  "cfg_kitty:kitty"
  "cfg_bat:bat"
  "cfg_starship.toml:starship.toml"
  "cfg_environment.d/10-fcitx5.conf:environment.d/10-fcitx5.conf"
  "cfg_fcitx5/profile:fcitx5/profile"
  "cfg_fcitx5/conf/classicui.conf:fcitx5/conf/classicui.conf"
  "cfg_fcitx5/conf/pinyin.conf:fcitx5/conf/pinyin.conf"
)

# 仓库路径:目标名，链接到 ${HOME}
HOME_LINKS=(
  "cfg_zshrc:.zshrc"
  "cfg_dolphin/open-terminal.desktop:.local/share/kio/servicemenus/open-terminal.desktop"
  "cfg_fcitx5/themes/Alpha-black:.local/share/fcitx5/themes/Alpha-black"
)

function usage()
{
  cat <<'EOF'
Usage: ./init.sh [options]

Symlink repo configs into ~/.config and ~:
  cfg_hyprland       -> ~/.config/hypr
  cfg_niri           -> ~/.config/niri
  cfg_waybar         -> ~/.config/waybar
  cfg_thunar         -> ~/.config/Thunar
  cfg_dolphin/dolphinrc
                     -> ~/.config/dolphinrc
  cfg_dolphin/open-terminal.desktop
                     -> ~/.local/share/kio/servicemenus/open-terminal.desktop
  cfg_kitty          -> ~/.config/kitty
  cfg_bat            -> ~/.config/bat
  cfg_starship.toml  -> ~/.config/starship.toml
  cfg_environment.d/10-fcitx5.conf
                     -> ~/.config/environment.d/10-fcitx5.conf
  cfg_fcitx5/profile -> ~/.config/fcitx5/profile
  cfg_fcitx5/conf/classicui.conf
                     -> ~/.config/fcitx5/conf/classicui.conf
  cfg_fcitx5/conf/pinyin.conf
                     -> ~/.config/fcitx5/conf/pinyin.conf
  cfg_fcitx5/themes/Alpha-black
                     -> ~/.local/share/fcitx5/themes/Alpha-black
  cfg_zshrc          -> ~/.zshrc

Options:
  -h, --help      Show this help
EOF
}

function link_one()
{
  local source="${1}" target="${2}"
  local target_dir

  if [[ ! -e "${source}" ]]; then
    log_fail "source not found: ${source}"
    exit 1
  fi

  target_dir="$(dirname -- "${target}")"
  mkdir -p -- "${target_dir}"

  if [[ -L "${target}" ]]; then
    local current
    current="$(readlink -f -- "${target}" || true)"
    if [[ "${current}" == "${source}" ]]; then
      log "Already linked: ${target} -> ${source}"
      return 0
    fi

    log "Replacing old symlink: ${target} (was ${current:-<broken>})"
    rm -- "${target}"
  elif [[ -e "${target}" ]]; then
    # 真实文件或目录：直接删除后让位给软链
    log "Removing existing path: ${target}"
    rm -rf -- "${target}"
  fi

  ln -s -- "${source}" "${target}"
  log "Linked: ${target} -> ${source}"
}

function main()
{
  local arg pair

  for arg in "${@}"; do
    case "${arg}" in
      -h|--help) usage; exit 0 ;;
      *) usage >&2; log_fail "unknown option: ${arg}"; exit 1; ;;
    esac
  done

  log "Repository: ${SCRIPT_DIR}"
  log "Config dir: ${CONFIG_DIR}"

  for pair in "${CONFIG_LINKS[@]}"; do
    link_one "${SCRIPT_DIR}/${pair%%:*}" "${CONFIG_DIR}/${pair##*:}"
  done

  for pair in "${HOME_LINKS[@]}"; do
    link_one "${SCRIPT_DIR}/${pair%%:*}" "${HOME}/${pair##*:}"
  done

  log "Done. Linked configs take effect immediately."
}

main "${@}"
