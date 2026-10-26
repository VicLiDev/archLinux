# SDDM Catppuccin Mocha 登录主题

本目录提供 SDDM 登录界面的主题配置，主题本身从上游发布包安装，
不直接复制进仓库。

- 主题：Catppuccin SDDM Mocha Blue 1.1.2
- 上游：<https://github.com/catppuccin/sddm>
- 许可证：MIT
- 登录背景：`~/Pictures/wallpapers/08-forest-path.jpg`
- 桌面壁纸仍使用 `cur_bkgrd.jpg`，两者互不影响

安装：

```bash
./ins_sddm_theme.sh
```

脚本会安装 Qt5 的 `qt5-quickcontrols2` 和 `qt5-svg`，下载主题，
复制到 `/usr/share/sddm/themes/catppuccin-mocha-blue`，并写入：

```text
/etc/sddm.conf.d/20-catppuccin-theme.conf
```

安装后注销或重启即可看到新登录界面。`ins_niri_env.sh` 和
`ins_hpld_env.sh` 在完整安装时也会调用这个脚本。
