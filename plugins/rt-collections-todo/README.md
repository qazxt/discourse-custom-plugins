## rt-collections-todo

在用户个人资料页增加 **My Collection** 与 **To do list** 两个可公开查看的列表，并允许用户编辑条目（产品名 + 图片上传 + 备注）。

### 路由/API

所有 API 都挂在 `/rt-collections-todo` 下：

- `GET /rt-collections-todo/u/:username/:list_type`（list_type: `collection` / `todo`）
- `POST /rt-collections-todo/u/:username/:list_type`
- `PUT /rt-collections-todo/u/:username/:list_type/:id`
- `DELETE /rt-collections-todo/u/:username/:list_type/:id`

### 站点设置

- `rt_collections_todo_enabled`

### 前端入口与文案

- 前端翻译：`config/locales/client.en.yml`、`client.zh_CN.yml`，结构为 `en: js: rt_collections_todo: ...`。
- 在 `assets/javascripts/discourse/route-map.js` 中把 `collection`、`todo` 挂到 **`user.userActivity`** 下，Ember 路由名为 `userActivity.collection` / `userActivity.todo`（仅有 `routes/user-activity/*.js` 不会自动进 Router）。
- 用户资料 **Activity** 页顶部的横向筛选栏通过核心 **`user-activity-bottom`** 插件出口注入 **My Collection**、**To do list**（与 `/u/:username/activity/collection`、`/activity/todo` 对应）。
- 用户卡片元数据区另有快捷链接（`user-card-metadata` connector）。

