/* eslint-disable ember/route-path-style, ember/routes-segments-snake-case */
/**
 * 必须由插件打包成 **独立** AMD 模块（requirejs 模块 id 以 `route-map` 结尾），供 mapping-router 扫描。
 * 勿被其它插件文件 import，否则会被 Rollup 打进 initializer 等 chunk，entries 里无 *route-map → 全站 404。
 * 使用 `rt-lucky-spin-route-map.js` 而非 `route-map.js`，避免与核心或其它插件在打包解析时的路径歧义。
 * 扁平 route + 绝对 path。
 */
export default function () {
  this.route("rt-lucky-spin", { path: "/lucky-spin" });
  this.route("rt-lucky-spin-admin", { path: "/lucky-spin/admin" });
}
