#!/bin/bash
set -u

# 锁屏后等待两分钟再熄屏；期间如果已经解锁，就取消熄屏。
if ! pidof hyprlock >/dev/null 2>&1; then
    hyprlock &
fi

(
    sleep 120
    if pidof hyprlock >/dev/null 2>&1; then
        hyprctl dispatch 'hl.dsp.dpms({ action = "off" })'
    fi
) &
