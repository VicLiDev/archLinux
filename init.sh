#!/usr/bin/env bash
#
# 把本仓库里的桌面配置链接到用户目录：
#
#   ~/.config/hypr -> <仓库>/cfg_hyprland
#   ~/.config/niri -> <仓库>/cfg_niri
#
# 之后所有修改都直接改仓库里的文件，两个合成器看到的永远是同一份。
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

# 仓库目录名:用户配置目录名
LINKS=(
  "cfg_hyprland:hypr"
  "cfg_niri:niri"
)

function usage()
{
  cat <<'EOF'
Usage: ./init.sh [options]

Symlink cfg_hyprland / cfg_niri to ~/.config/hypr and ~/.config/niri.

Options:
  -h, --help      Show this help
EOF
}

function link_one()
{
  local source="${1}" name="${2}"
  local target="${CONFIG_DIR}/${name}"

  if [[ ! -d "${source}" ]]; then
    log_fail "source directory not found: ${source}"
    exit 1
  fi
  mkdir -p -- "${CONFIG_DIR}"

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

  for pair in "${LINKS[@]}"; do
    link_one "${SCRIPT_DIR}/${pair%%:*}" "${pair##*:}"
  done

  log "Done. Changes under ${SCRIPT_DIR}/cfg_hyprland or cfg_niri take effect immediately."
}

main "${@}"
