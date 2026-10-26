#!/bin/bash
set -u

# 锁屏后等待两分钟再熄屏；期间如果已经解锁，就取消熄屏。
if ! pidof swaylock >/dev/null 2>&1; then
    swaylock -f || exit 1
fi

(
    sleep 120
    if pidof swaylock >/dev/null 2>&1; then
        niri msg action power-off-monitors
    fi
) &
