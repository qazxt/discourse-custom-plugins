import UserActivityRoute from "discourse/routes/user-activity";

export default class UserActivityTodoRoute extends UserActivityRoute {
  setupController(controller, user) {
    super.setupController(controller, user);
    controller.set("model", user);
  }
}
