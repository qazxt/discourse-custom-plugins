import { withPluginApi } from "discourse/lib/plugin-api";
import { i18n } from "discourse-i18n";

export default {
  name: "rt-lucky-spin",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      api.addRoute?.("rtLuckySpin", { path: "/lucky-spin" });
      api.addRoute?.("rtLuckySpinAdmin", { path: "/lucky-spin/admin" });
      api.addCommunitySectionLink?.({
        name: "rt_lucky_spin",
        route: "rtLuckySpin",
        title: i18n("rt_lucky_spin.menu_title"),
        text: i18n("rt_lucky_spin.menu_title"),
      });
    });
  },
};

