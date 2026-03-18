import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "rt-collections-todo",
  initialize(container) {
    withPluginApi("0.8.7", (api) => {
      api.addUserNavigationItem({
        name: "my_collection",
        displayName: i18n("rt_collections_todo.my_collection"),
        href: (user) => `/u/${user.username}/activity/collection`,
      });

      api.addUserNavigationItem({
        name: "to_do_list",
        displayName: i18n("rt_collections_todo.to_do_list"),
        href: (user) => `/u/${user.username}/activity/todo`,
      });
    });
  },
};

