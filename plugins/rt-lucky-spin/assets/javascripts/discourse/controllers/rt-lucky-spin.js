import Controller from "@ember/controller";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";

export default class RtLuckySpinController extends Controller {
  @service currentUser;
  @tracked spinning = false;
  @tracked result = null;

  @action
  async spin() {
    this.spinning = true;
    this.result = null;
    try {
      const res = await ajax("/rt-lucky-spin/spin", { type: "POST" });
      this.result = res;
      this.model = await ajax("/rt-lucky-spin/state");
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.spinning = false;
    }
  }
}

