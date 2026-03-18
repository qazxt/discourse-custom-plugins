## rt-lucky-spin

每日登录获得一次“Spin & WIN”抽奖机会（可累积），抽奖可获得积分（联通 Discourse Gamification）或“谢谢参与”，也支持配置产品奖励并通知管理员。

### 站点设置

- `rt_lucky_spin_enabled`
- `rt_lucky_spin_daily_grant_enabled`
- 权重：`rt_lucky_spin_points_100_weight` / `rt_lucky_spin_points_25_weight` / `rt_lucky_spin_points_5_weight` / `rt_lucky_spin_no_prize_weight`
- 产品奖：`rt_lucky_spin_product_prizes`（list）
- 周度约束：`rt_lucky_spin_weekly_deadline_wday` / `rt_lucky_spin_weekly_deadline_hour` / `rt_lucky_spin_weekly_deadline_minute` / `rt_lucky_spin_weekly_force_window_hours`
- 产品奖触发概率：`rt_lucky_spin_product_prize_chance_per_mille`（千分比）
- 加分来源文本：`rt_lucky_spin_points_source_label`
- 管理员通知：`rt_lucky_spin_admin_notify_username`

### API

- `GET /rt-lucky-spin/state`
- `POST /rt-lucky-spin/spin`
- `GET /rt-lucky-spin/history`
- `GET /rt-lucky-spin/admin/weekly`（管理员）
- `PUT /rt-lucky-spin/admin/weekly/:id/shipping`（管理员）

