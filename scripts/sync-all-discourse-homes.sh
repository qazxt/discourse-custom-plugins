#!/usr/bin/env bash
# 对所有已存在的 discourse/plugins 各执行一次同步（多用户 / 多副本）
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/sync-plugins-to-discourse.sh"
for p in /root/discourse/plugins /home/*/discourse/plugins; do
  [[ -d "$p" ]] || continue
  echo "=== $p ==="
  DISCOURSE_PLUGINS_DIR="$p" bash "$SYNC"
done
echo "全部完成"
