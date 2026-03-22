#!/usr/bin/env bash
# 打印可能的 Discourse plugins 目录（存在则输出）
for base in "$HOME" /home/*; do
  [[ -d "$base" ]] || continue
  p="$base/discourse/plugins"
  if [[ -d "$p" ]]; then
    echo "$p"
  fi
done
