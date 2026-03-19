import UserActivityRoute from "discourse/routes/user-activity";

export default class UserActivityTodoRoute extends UserActivityRoute {
  model(params) {
    return super.model(params).then((model) => {
      model.set("rtCollectionsTodoListType", "todo");
      return model;
    });
  }
}

