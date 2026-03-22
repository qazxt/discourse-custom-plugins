import UserActivityRoute from "discourse/routes/user-activity";

export default class UserActivityCollectionRoute extends UserActivityRoute {
  setupController(controller, user) {
    super.setupController(controller, user);
    // 核心 UserActivityRoute 只给父级 user-activity 设 model，子路由模板里的 this.model 一直是 undefined
    controller.set("model", user);
  }
}
