import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class RtCollectionsTodoTabs extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.rt_collections_todo_enabled}}
      {{! user 路由需要动态段 username，否则 generate URL 会抛错 }}
      {{#if @model}}
        <li
          class="user-activity-bottom-outlet rt-collections-todo-tab-collection"
        >
          <LinkTo @route="userActivity.collection" @model={{@model}}>
            {{icon "bookmark"}}
            <span>{{i18n "rt_collections_todo.my_collection"}}</span>
          </LinkTo>
        </li>
        <li class="user-activity-bottom-outlet rt-collections-todo-tab-todo">
          <LinkTo @route="userActivity.todo" @model={{@model}}>
            {{icon "list"}}
            <span>{{i18n "rt_collections_todo.to_do_list"}}</span>
          </LinkTo>
        </li>
      {{/if}}
    {{/if}}
  </template>
}
