#!/usr/bin/env bash
# Broccoli EACCES 排障：在 WSL 执行，把完整输出贴给维护者
set -eu
CTR="${DISCOURSE_DEV_CONTAINER:-discourse_dev}"
PATH_JS="/src/plugins/rt-lucky-spin/assets/javascripts"

echo "=== 1) docker 与容器 ==="
command -v docker >/dev/null 2>&1 && docker ps -a --format 'table {{.Names}}\t{{.Status}}' | head -30 || echo "无 docker 命令"

echo ""
echo "=== 2) 容器 $CTR 是否存在且在运行 ==="
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CTR"; then
  echo "运行中: $CTR"
else
  echo "未在运行或名称不匹配。当前运行中的容器名见上表，可: export DISCOURSE_DEV_CONTAINER=实际名字"
fi

echo ""
echo "=== 3) 路径权限链（容器内）==="
if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CTR"; then
  docker exec -u root "$CTR" sh -c "ls -ld /src /src/plugins /src/plugins/rt-lucky-spin /src/plugins/rt-lucky-spin/assets $PATH_JS 2>&1"
  echo ""
  echo "=== 4) 文件系统类型 ==="
  docker exec -u root "$CTR" df -T /src/plugins 2>&1 || true
  echo ""
  echo "=== 5) discourse 用户 node stat ==="
  docker exec -u discourse "$CTR" node -e "require('fs').statSync('$PATH_JS'); console.log('stat ok')" 2>&1 || echo "stat 失败"
  echo ""
  echo "=== 6) root 用户 node stat ==="
  docker exec -u root "$CTR" node -e "require('fs').statSync('$PATH_JS'); console.log('stat ok')" 2>&1 || echo "stat 失败"
  echo ""
  echo "=== 7) Ember 相关进程（若有）==="
  docker exec -u root "$CTR" sh -c "ps aux 2>/dev/null | grep -E '[e]mber|[n]ode.*discourse' | head -15" || true
else
  echo "跳过容器内检查（容器未运行）"
fi

echo ""
echo "=== 8) 宿主机 DISCOURSE_PLUGINS_DIR（若已设置）==="
D="${DISCOURSE_PLUGINS_DIR:-}"
if [[ -n "$D" && -d "$D" ]]; then
  ls -ld "$D" "$D/rt-lucky-spin/assets/javascripts" 2>&1 || true
else
  echo "未设置 DISCOURSE_PLUGINS_DIR；常见为 /root/discourse/plugins 或 ~/discourse/plugins"
fi

echo ""
echo "完成。若 NTFS（/mnt/c、/mnt/e）上直接挂载进容器，可能出现容器内 EACCES，请把 Discourse 放在 WSL ext4（如 /root/discourse）并用 sync 脚本拷插件。"
