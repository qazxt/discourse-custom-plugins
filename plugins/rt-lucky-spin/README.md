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

- **积分界面不刷新**：`User#gamification_score`（discourse-gamification）读 **LeaderboardCachedView 物化视图**；加分后插件会执行与定时任务相同的 `purge_all_stale` → `refresh_all` → `create_all`，且前端抽奖成功后会 `currentUser.findDetails()`。
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



rt-lucky-spin（幸运转盘） 插件当前后台可配置项、功能含义和推荐配置方式。

一、总开关与发次数
rt_lucky_spin_enabled

作用：总开关。关闭后 /lucky-spin 以及抽奖 API 会被拦截（控制器 ensure_enabled 直接 NotFound）。
怎么配：上线前开；要临时下线就关。
rt_lucky_spin_daily_grant_enabled

作用：是否启用“每日登录赠送 1 次抽奖机会”。
怎么配：一般开；如果想只通过运营脚本发次数就关。
二、积分/谢谢参与权重（决定 points/no_prize 的概率）
这 4 个只影响“非保底 product 的情况下”，轮盘随机池里 points/no_prize 的占比：

rt_lucky_spin_points_100_weight：抽到 100 分的权重
rt_lucky_spin_points_25_weight：抽到 25 分的权重
rt_lucky_spin_points_5_weight：抽到 5 分的权重
rt_lucky_spin_no_prize_weight：谢谢参与的权重
怎么配：权重是相对值（越大越常出）。例如 1/4/12/30 会让“谢谢参与”最常见、100 分最稀有。

三、积分事件来源文案
rt_lucky_spin_points_source_label
作用：写入 gamification 事件时的 description（例如 “Lucky Spin”），方便后台/统计识别。
怎么配：写你们运营希望看到的来源名即可。
四、产品奖（礼品）配置：名单、概率、截止、末尾窗口保底
rt_lucky_spin_product_prizes（list，textarea）

作用：产品奖品名称列表（每个名称在“每周”维度最多被发出一次）。
怎么配：一行一个奖品名即可（插件兼容 | 或换行分隔）。
rt_lucky_spin_product_prize_chance_per_mille

作用：非末尾窗口时，“本次是否允许出现 product 扇区”的千分比概率（0~1000）。
怎么配：
5 ≈ 0.5% 允许出现 product
200 ≈ 20%
1000 ≈ 100%（只代表“允许出现”，末尾窗口外仍要看权重池最终落点）
rt_lucky_spin_weekly_deadline_wday / hour / minute

作用：定义每周的“截止时刻”（周一作为周起点，wday 用 0=周日..6=周六 映射）。
怎么配：按运营习惯设置“每周几几点截止”。
rt_lucky_spin_weekly_force_window_hours（末尾窗口配置）

作用：截止时间前 N 小时进入“末尾窗口”。
怎么配：比如 24 表示最后 24 小时。
末尾窗口保底（你刚选的方案 A）
当前逻辑是：末尾窗口内，如果本周产品奖还没出过（且仍有未发名额），将 直接保底本次抽奖结果为 product（跳过权重随机），确保“末尾窗口只要有人抽，就会出一次礼品”。

五、通知（产品奖中奖提醒）
rt_lucky_spin_admin_notify_username（type: username）
作用：有人中产品奖时，给该用户名发私信提醒（不填则不通知）。
怎么配：填一个管理员/运营账号用户名即可。
推荐的“最常见配置模板”
想要“平时较难中、末尾保底出 1 个”：

product_prize_chance_per_mille = 10 ~ 50
weekly_force_window_hours = 24（最后一天保底）
points/no_prize 权重按你们运营节奏调
想要“礼品更常出”：

适当提高 product_prize_chance_per_mille（例如 200）
同时把 points/no_prize 权重调低（否则即使允许出现 product，也经常落不到）
