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

