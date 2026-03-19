import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class RtLuckySpinAdminRoute extends Route {
  model() {
    return ajax("/rt-lucky-spin/admin/weekly");
  }
}

