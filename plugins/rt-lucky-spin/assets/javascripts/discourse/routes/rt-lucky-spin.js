import Route from "@ember/routing/route";
import { ajax } from "discourse/lib/ajax";

export default class RtLuckySpinRoute extends Route {
  model() {
    return ajax("/rt-lucky-spin/state");
  }
}

