#!/usr/bin/env bash
# 同步插件 → 清 rt-lucky-spin 生成 JS →（可选）重启 discourse_dev 容器
set -eu
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT"

bash "$SCRIPT_DIR/sync-all-discourse-homes.sh"

for base in /root/discourse /home/*/discourse; do
  [[ -d "$base/app/assets/generated" ]] 2>/dev/null || continue
  if [[ -d "$base/app/assets/generated/rt-lucky-spin" ]]; then
    rm -rf "$base/app/assets/generated/rt-lucky-spin"
    echo "已删: $base/app/assets/generated/rt-lucky-spin"
  fi
done

if command -v docker >/dev/null 2>&1; then
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'discourse_dev'; then
    echo "重启容器 discourse_dev …"
    docker restart discourse_dev
    echo "完成。请在容器/宿主按惯例重新拉起 ./d/rails s 与 ./d/ember-cli（若 boot_dev 未自动起）。"
  else
    echo "未检测到运行中的 discourse_dev，已跳过 docker restart。"
    echo "请在本机 Discourse 目录手动重启 ./d/rails s 与 ./d/ember-cli。"
  fi
else
  echo "未找到 docker 命令，已跳过容器重启。"
fi

echo "全部步骤执行完毕。"
