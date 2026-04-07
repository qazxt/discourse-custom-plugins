## rt-collections-todo

在用户个人资料页增加 **My Collection** 与 **To do list** 两个可公开查看的列表，并允许用户编辑条目（产品名 + 图片上传 + 备注）。

### 安装与启用（是否需要建表？）

**需要。** 本插件包含数据库迁移 `db/migrate/20260318212000_create_rt_collections_todo_items.rb`，会创建表 `rt_collections_todo_items`（含 `upload_id` 字段用于关联 Discourse 的 `uploads`）。

- **首次安装**：把插件放入 Discourse 的 `plugins/` 后，执行数据库迁移，然后重启。
- **升级插件**：若本插件新增了 migration，同样需要再次执行迁移。

在开发容器里常用命令（示例）：

```bash
rake db:migrate
```

（具体以你的 Discourse 部署方式为准；核心点是：**migration 必须跑过**。）

启用开关：

- `rt_collections_todo_enabled`
- `rt_collections_todo_notes_max_length`（备注最大字数，默认 250）

### 使用流程（用户视角）

- **入口**：
  - 用户个人资料页 `Activity` 顶部筛选栏会出现 **我的收藏 / 待办清单**。
  - 用户卡片上，**用户名下方**会出现「我的收藏 / 待办清单」快捷入口（`user-card-after-username` outlet）。
- **查看**：所有人可查看用户的列表页面（公开展示）。
- **编辑**：仅当访问者为该用户本人时显示 **添加条目**、**编辑**、**删除** 按钮。
- **新增条目**：填写产品名、备注（可选）、上传图片（可选）→ 保存后出现在列表中。
- **编辑条目**：可再次修改产品名、备注、图片并保存。
- **删除条目**：点击垃圾桶按钮删除该条目。

### 图片上传存储位置

图片上传走 Discourse 的标准上传接口 `POST /uploads.json`，插件只保存 `upload_id`，展示 URL 来自 `Upload#url`。

- 若站点使用本地存储：文件落在 Discourse 的 uploads 目录（由站点配置/容器卷决定）。
- 若站点启用 S3/对象存储：文件在对应存储桶中。

因此在开发环境如果重建/重启容器且 uploads 未做持久化挂载，**图片文件可能会丢失**，但条目里的 `upload_id` 仍可能存在。

### 路由/API

所有 API 都挂在 `/rt-collections-todo` 下：

- `GET /rt-collections-todo/u/:username/:list_type`（list_type: `collection` / `todo`）
- `POST /rt-collections-todo/u/:username/:list_type`
- `PUT /rt-collections-todo/u/:username/:list_type/:id`
- `DELETE /rt-collections-todo/u/:username/:list_type/:id`

### 站点设置

- `rt_collections_todo_enabled`
- `rt_collections_todo_notes_max_length`

### 前端入口与文案

- 前端翻译：`config/locales/client.en.yml`、`client.zh_CN.yml`，结构为 `en: js: rt_collections_todo: ...`。
- 在 `assets/javascripts/discourse/route-map.js` 中把 `collection`、`todo` 挂到 **`user.userActivity`** 下，Ember 路由名为 `userActivity.collection` / `userActivity.todo`（仅有 `routes/user-activity/*.js` 不会自动进 Router）。
- 用户资料 **Activity** 页顶部的横向筛选栏通过核心 **`user-activity-bottom`** 插件出口注入 **My Collection**、**To do list**（与 `/u/:username/activity/collection`、`/activity/todo` 对应）。
- 用户卡片快捷链接接在 **`user-card-after-username`**（与 `user-card-metadata` 相比更靠上，在简介之前）。

