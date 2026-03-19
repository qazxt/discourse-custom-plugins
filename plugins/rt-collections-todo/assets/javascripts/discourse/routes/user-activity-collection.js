import UserActivityRoute from "discourse/routes/user-activity";

export default class UserActivityCollectionRoute extends UserActivityRoute {
  model(params) {
    return super.model(params).then((model) => {
      model.set("rtCollectionsTodoListType", "collection");
      return model;
    });
  }
}

