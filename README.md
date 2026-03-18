## discouse-plugins

这个仓库包含多个 Discourse 插件（monorepo）：

- `plugins/rt-collections-todo`：个人资料页的 My Collection / To do list（可编辑产品名+上传图片、可公开查看）
- `plugins/rt-lucky-spin`：每日登录抽奖（可累积次数），积分联通 Discourse Gamification，支持周度产品奖与发货状态

### 安装方式（自建 Discourse）

将本仓库作为一个 git 源加入 Discourse 容器的插件列表（示例以 app.yml 为准）：把 `plugins/` 目录下需要的插件拷贝/挂载到 Discourse 的 `plugins/`。

最简单方式：把整个仓库放到 Discourse 的 `plugins/` 下（保持 `plugins/rt-xxx` 结构），重建容器并运行迁移。

### 主要入口

- Lucky Spin 页面：`/lucky-spin`
- Lucky Spin API：`/rt-lucky-spin/*`
- Collections/ToDo API：`/rt-collections-todo/*`

