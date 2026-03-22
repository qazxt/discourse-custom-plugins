## rt-lucky-spin

每日登录获得一次“Spin & WIN”抽奖机会（可累积），抽奖可获得积分（联通 Discourse Gamification）或“谢谢参与”，也支持配置产品奖励并通知管理员。

### 站点设置

- `rt_lucky_spin_enabled`（**不再**使用 `enabled_site_setting`，否则关闭时 Discourse 不加载插件 JS，`/lucky-spin` 会进 Ember unknown → permalink 404；侧栏入口由 initializer 按本设置隐藏，API/HTML 仍由 `ensure_enabled` 控制）
- `rt_lucky_spin_daily_grant_enabled`
- 权重：`rt_lucky_spin_points_100_weight` / `rt_lucky_spin_points_25_weight` / `rt_lucky_spin_points_5_weight` / `rt_lucky_spin_no_prize_weight`
- 产品奖：`rt_lucky_spin_product_prizes`（list）
- 周度约束：`rt_lucky_spin_weekly_deadline_wday` / `rt_lucky_spin_weekly_deadline_hour` / `rt_lucky_spin_weekly_deadline_minute` / `rt_lucky_spin_weekly_force_window_hours`
- 产品奖触发概率：`rt_lucky_spin_product_prize_chance_per_mille`（千分比）
- 加分来源文本：`rt_lucky_spin_points_source_label`
- 管理员通知：`rt_lucky_spin_admin_notify_username`

### 前端路由与文案

- **`rt-lucky-spin-route-map.js`**：扁平注册 `rt-lucky-spin`、`rt-lucky-spin-admin`（模块 id 仍以 `route-map` 结尾，供 `mapRoutes` 扫描）。**禁止**在 initializers / 其它模块里 `import` 本文件（Rollup 会合并 chunk，导致 `requirejs.entries` 无对应键 → permalink `found: false`）。**勿**使用 `enabled_site_setting` 关整包 JS（已移除）。
- 侧栏 `initializers/rt-lucky-spin.js` 使用 **`href: getURL("/lucky-spin")`**，不要写 `route`。
- 前端翻译放在 **`config/locales/client.en.yml`**、**`client.zh_CN.yml`**，结构为 `en: js: rt_lucky_spin: ...`（见仓库内示例）。不要使用已移除的 `api.addRoute`。

### Rails HTML 路由（与 Ember 路径一致）

- `GET /lucky-spin`、`GET /lucky-spin/admin` 由 `LuckySpinHtmlController` 渲染 Discourse 的 `application` / 开发环境 `ember_cli` 布局，避免仅在前端注册 `/lucky-spin` 时 **直访 :3000 或硬刷新** 出现 **Routing Error**（`permalink` 通配路由只在存在 Permalink 记录时命中）。

### API

- `GET /rt-lucky-spin/state`
- `POST /rt-lucky-spin/spin`
- `GET /rt-lucky-spin/history`
- `GET /rt-lucky-spin/admin/weekly`（管理员）
- `PUT /rt-lucky-spin/admin/weekly/:id/shipping`（管理员）

### 排障（`/state` 等在 localhost:4200 报 500）

- **NoMethodError + `ensure_logged_in`**：`Guardian` **没有** `ensure_logged_in`；插件控制器应使用 **`ApplicationController#ensure_logged_in`**（`before_action`），或 **`guardian.ensure_authenticated!`**。勿写 `guardian.ensure_logged_in`。
- **check_xhr / 代理**：本插件对 `state` / `history`（及管理员 `weekly`）已 `skip_before_action :check_xhr`，GET 路由带 `defaults: { format: :json }`。改 `.rb` / `routes.rb` 后请同步插件并 **重启 Rails**。
