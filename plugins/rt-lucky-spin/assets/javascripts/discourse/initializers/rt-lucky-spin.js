// 切勿 import 任何 *route-map* 文件：Rollup 会合并进本模块，requirejs.entries 里不再有以 route-map 结尾的键，
// mapping-router 的 mapRoutes() 依赖独立 module id（/route-map$/），否则 /lucky-spin 永远 unknown → permalink false。

import { withPluginApi } from "discourse/lib/plugin-api";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";

export default {
  name: "rt-lucky-spin",
  initialize() {
    withPluginApi("0.8.7", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (!siteSettings.rt_lucky_spin_enabled) {
        return;
      }
      // 只用 href，不用 route：侧栏 SectionLink 在 @href 存在时走 <a> + intercept-click → Router。
      // 路由由 discourse/rt-lucky-spin-route-map.js 注册为 rt-lucky-spin（URL /lucky-spin）。
      api.addCommunitySectionLink({
        name: "rt_lucky_spin",
        href: getURL("/lucky-spin"),
        title: i18n("rt_lucky_spin.menu_title"),
        text: i18n("rt_lucky_spin.menu_title"),
      });
    });
  },
};

