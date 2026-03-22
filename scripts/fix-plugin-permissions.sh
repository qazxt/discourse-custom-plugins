#!/usr/bin/env bash
# 仅修正属主与权限，不拷贝源码。EACCES 时可在 WSL 里直接执行本脚本。
set -eu
DST="${DISCOURSE_PLUGINS_DIR:-$HOME/discourse/plugins}"
if [[ ! -d "$DST" ]]; then
  echo "用法: DISCOURSE_PLUGINS_DIR=/你的/discourse/plugins bash scripts/fix-plugin-permissions.sh"
  exit 1
fi
OWNER=$(stat -c '%u:%g' "$DST")
for name in rt-collections-todo rt-lucky-spin; do
  [[ -d "$DST/$name" ]] || continue
  chown -R "$OWNER" "$DST/$name"
  if [[ "${SYNC_PLUGINS_CHMOD_777:-0}" == "1" ]]; then
    chmod -R 777 "$DST/$name"
    echo "OK $DST/$name -> chown $OWNER, chmod 777"
  else
    chmod -R a+rX "$DST/$name"
    echo "OK $DST/$name -> chown $OWNER, chmod a+rX"
  fi
done

# 绑定挂载时，有时需在容器内再对齐一次（与 discourse 进程用户一致）
# 注意：仅修插件子目录不够——若 /src/plugins 对 node 用户不可进入（缺 o+x），仍会 EACCES
CTR="${DISCOURSE_DEV_CONTAINER:-discourse_dev}"
if ! command -v docker >/dev/null 2>&1; then
  echo "提示: 未找到 docker，仅修了宿主机 $DST" >&2
elif ! docker ps --format '{{.Names}}' 2>/dev/null | grep -qx "$CTR"; then
  echo "提示: 未检测到运行中的容器「$CTR」，仅修了宿主机。请 docker start $CTR 后再执行本脚本，或设置 DISCOURSE_DEV_CONTAINER=你的容器名" >&2
else
  if ! docker exec -u root -e SYNC_PLUGINS_CHMOD_777="${SYNC_PLUGINS_CHMOD_777:-0}" "$CTR" sh -ec '
    # 父目录必须可遍历，否则 stat 子路径会 EACCES
    chmod a+rx /src/plugins 2>/dev/null || true
    for p in /src/plugins/rt-lucky-spin /src/plugins/rt-collections-todo; do
      [ -d "$p" ] || continue
      chown -R discourse:discourse "$p"
    done
    if [ "$SYNC_PLUGINS_CHMOD_777" = "1" ]; then
      chmod -R 777 /src/plugins/rt-lucky-spin /src/plugins/rt-collections-todo
    else
      chmod -R a+rX /src/plugins/rt-lucky-spin /src/plugins/rt-collections-todo
    fi
    # 再兜底：目录统一 a+rx（避免某层被设成 700）
    for p in /src/plugins/rt-lucky-spin /src/plugins/rt-collections-todo; do
      [ -d "$p" ] || continue
      find "$p" -type d -exec chmod a+rx {} +
    done
  '; then
    echo "错误: 容器 $CTR 内 chown/chmod 失败。请运行: bash scripts/diagnose-plugin-eacces.sh" >&2
    exit 1
  fi
  # 与 ./d/ember-cli 相同用户（discourse）下再 stat 一次，避免「脚本显示 OK 实际仍 EACCES」
  if ! docker exec -u discourse "$CTR" node -e 'require("fs").statSync("/src/plugins/rt-lucky-spin/assets/javascripts")'; then
    echo "错误: 容器内 discourse 用户仍无法 stat javascripts。请运行: bash scripts/diagnose-plugin-eacces.sh" >&2
    exit 1
  fi
  echo "OK 容器 $CTR 内已修复 /src/plugins、两插件，且 discourse 用户 stat 通过"
fi
