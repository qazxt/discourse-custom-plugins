#!/usr/bin/env bash
# 同步插件 → 清 rt-lucky-spin 生成物 → 重启 discourse_dev → 启动 Rails + Ember（nohup）
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DISCOURSE_ROOT="${DISCOURSE_ROOT:-/root/discourse}"

cd "$REPO_ROOT"
bash "$SCRIPT_DIR/sync-all-discourse-homes.sh"

if [[ -d "$DISCOURSE_ROOT/app/assets/generated" ]]; then
  rm -rf "$DISCOURSE_ROOT/app/assets/generated/rt-lucky-spin" || true
  echo "已删(宿主机): $DISCOURSE_ROOT/app/assets/generated/rt-lucky-spin"
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "错误: 未找到 docker"
  exit 1
fi

echo "重启容器 discourse_dev …"
docker restart discourse_dev

echo "等待容器就绪(约 15s)…"
sleep 15

docker exec discourse_dev bash -lc 'rm -rf /src/app/assets/generated/rt-lucky-spin 2>/dev/null || true'
echo "已尝试清理容器内 /src/app/assets/generated/rt-lucky-spin"

cd "$DISCOURSE_ROOT"

mkdir -p /tmp
# 文档：避免叠多套；容器整重启后一般无旧进程，此处仅温和清理常见 dev 进程名
docker exec -u discourse:discourse discourse_dev bash -lc \
  'pkill -f "bin/rails server" 2>/dev/null || true; pkill -f "ember server" 2>/dev/null || true; pkill -f "bin/ember-cli" 2>/dev/null || true' \
  || true
sleep 2

echo "启动 Rails (nohup → /tmp/discourse-rails.log)…"
nohup ./d/rails s >> /tmp/discourse-rails.log 2>&1 &
echo "Rails 后台已启动 (pid $!)"

sleep 3

echo "启动 Ember (nohup → /tmp/discourse-ember.log)…"
nohup ./d/ember-cli >> /tmp/discourse-ember.log 2>&1 &
echo "Ember 后台已启动 (pid $!)"

echo ""
echo "======== 完成 ========"
echo "日志: tail -f /tmp/discourse-rails.log   /tmp/discourse-ember.log"
echo "待 Ember 出现 Build successful 后访问 http://127.0.0.1:4200"
echo "Rails 日志末尾:"
tail -n 8 /tmp/discourse-rails.log 2>/dev/null || true
