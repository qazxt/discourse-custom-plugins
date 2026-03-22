#!/usr/bin/env bash
# 在容器内检查转盘插件表是否存在（WSL: docker exec discourse_dev bash /path/to/this.sh）
set -eu
cd /src
bin/rails runner "puts 'spin_events=' + RtLuckySpin::SpinEvent.table_exists?.to_s; puts 'weekly=' + RtLuckySpin::WeeklyPrize.table_exists?.to_s"
