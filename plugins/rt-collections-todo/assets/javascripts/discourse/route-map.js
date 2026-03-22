/**
 * 将自定义页挂在 /u/:username/activity/collection 与 .../todo。
 * 需在此处声明，否则仅有 routes/user-activity/*.js 不会出现在 Router 中，
 * LinkTo @route="userActivity.collection" 会报 “no route named …”。
 */
export default {
  resource: "user.userActivity",
  map() {
    this.route("collection", { path: "collection" });
    this.route("todo", { path: "todo" });
  },
};
