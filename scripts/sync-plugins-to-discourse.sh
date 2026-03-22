#!/usr/bin/env bash
set -eu
# 从本仓库同步插件到 WSL 内 Discourse（默认 ~/discourse/plugins）
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/plugins"

if [[ -n "${DISCOURSE_PLUGINS_DIR:-}" ]]; then
  DST="$DISCOURSE_PLUGINS_DIR"
else
  CANDIDATES=()
  for p in "$HOME/discourse/plugins" /home/*/discourse/plugins; do
    [[ -d "$p" ]] && CANDIDATES+=("$p")
  done
  if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
    echo "错误: 未找到 discourse/plugins（试过 \$HOME 与 /home/*/discourse/plugins）"
    echo "请: export DISCOURSE_PLUGINS_DIR=/你的/discourse/plugins"
    exit 1
  elif [[ ${#CANDIDATES[@]} -eq 1 ]]; then
    DST="${CANDIDATES[0]}"
  else
    echo "错误: 发现多个 plugins 目录，请指定其一："
    printf '  %s\n' "${CANDIDATES[@]}"
    echo "export DISCOURSE_PLUGINS_DIR=上面选一条"
    exit 1
  fi
fi

if [[ ! -d "$DST" ]]; then
  echo "错误: 目标目录不存在: $DST"
  exit 1
fi

sync_one() {
  local name="$1"
  rm -rf "$DST/$name"
  # 勿用 cp -a：从 /mnt/e（NTFS）拷到 ext4 时常把 Windows 侧权限/属主一并保留，容器内会 EACCES
  cp -r "$SRC/$name" "$DST/"
}

sync_one rt-collections-todo
sync_one rt-lucky-spin

# 与 plugins 父目录属主一致，避免 Docker 内 Ember/Broccoli 对挂载目录 EACCES
# 设置 SYNC_PLUGINS_CHOWN=0 可跳过
fix_ownership() {
  if [[ "${SYNC_PLUGINS_CHOWN:-1}" == "0" ]]; then
    echo "已跳过 chown（SYNC_PLUGINS_CHOWN=0）"
    return 0
  fi

  local owner spin_owner collection_owne
  owner=$(stat -c '%u:%g' "$DST")
  spin_owner=$(stat -c '%u:%g' "$DST/rt-lucky-spin")
  collection_owner=$(stat -c '%u:%g' "$DST/rt-collections-todo")

  if [[ "$(id -u)" -eq 0 ]]; then
    chown -R "$owner" "$DST/rt-collections-todo" "$DST/rt-lucky-spin"
    echo "已 chown -R $owner（与 $DST 一致）"
    if [[ "${SYNC_PLUGINS_CHMOD_777:-0}" == "1" ]]; then
      chmod -R 777 "$DST/rt-collections-todo" "$DST/rt-lucky-spin"
      echo "已 chmod -R 777（仅开发排障用，设 SYNC_PLUGINS_CHMOD_777=0 可关）"
    else
      chmod -R a+rX "$DST/rt-collections-todo" "$DST/rt-lucky-spin"
      echo "已 chmod -R a+rX（保证容器内可 stat/遍历）"
    fi
    return 0
  fi

  if [[ "$spin_owner" == "$owner" && "$collection_owner" == "$owner" ]]; then
    chmod -R a+rX "$DST/rt-collections-todo" "$DST/rt-lucky-spin" 2>/dev/null || true
    echo "属主已与 $DST 一致 ($owner)；已尝试 chmod a+rX（失败可忽略）"
    return 0
  fi

  echo "警告: 插件目录属主为 rt-lucky-spin=$spin_owner rt-collections-todo=$collection_owner，与 $DST ($owner) 不一致。"
  echo "容器内 ./d/ember-cli 可能对插件目录报 EACCES（Broccoli WatchedDir）。请执行:"
  echo "  sudo chown -R \"$owner\" \"$DST/rt-collections-todo\" \"$DST/rt-lucky-spin\""
  echo "  sudo chmod -R a+rX \"$DST/rt-collections-todo\" \"$DST/rt-lucky-spin\""
}

fix_ownership

echo "已同步到: $DST"
echo "检查是否仍存在 addUserNavigationItem({ 调用..."
if grep -R "addUserNavigationItem({" "$DST/rt-collections-todo" --include='*.js' --include='*.gjs' 2>/dev/null; then
  echo "错误: 仍存在 addUserNavigationItem（请更新本仓库后重试）"
  exit 1
fi
echo "OK"
