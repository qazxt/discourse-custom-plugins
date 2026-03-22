/**
 * user-card-metadata outlet 已由核心把 user 注入 PluginConnector（计算属性）。
 * 切勿 setupComponent 里 component.set("user", …)，否则会触发：
 * Assertion Failed: Cannot override the computed property `user`
 */
export default {};
