import Controller from "@ember/controller";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class RtLuckySpinAdminController extends Controller {
  @tracked savingId = null;

  @action
  async updateShipping(prize, shippingStatus, shippingNote) {
    this.savingId = prize.id;
    try {
      const updated = await ajax(`/rt-lucky-spin/admin/weekly/${prize.id}/shipping`, {
        type: "PUT",
        data: { shipping_status: shippingStatus, shipping_note: shippingNote },
      });

      this.model = this.model.map((p) => (p.id === updated.id ? updated : p));
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.savingId = null;
    }
  }
}

