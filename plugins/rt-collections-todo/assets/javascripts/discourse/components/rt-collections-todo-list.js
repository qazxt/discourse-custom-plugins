import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { inject as service } from "@ember/service";
import Uploader from "discourse/lib/uploader";
import { i18n } from "discourse-i18n";

export default class RtCollectionsTodoList extends Component {
  @service currentUser;
  @tracked items = [];
  @tracked loading = true;
  @tracked editingId = null;
  @tracked newTitle = "";
  @tracked newNotes = "";
  @tracked newUploadId = null;

  constructor() {
    super(...arguments);
    this.load();
  }

  get canEdit() {
    return this.currentUser?.username === this.args.user.username;
  }

  get headerTitle() {
    return this.args.listType === "collection"
      ? i18n("rt_collections_todo.my_collection")
      : i18n("rt_collections_todo.to_do_list");
  }

  get apiBase() {
    return `/rt-collections-todo/u/${this.args.user.username}/${this.args.listType}`;
  }

  async load() {
    this.loading = true;
    try {
      const result = await ajax(this.apiBase);
      this.items = result.items || [];
    } catch (e) {
      popupAjaxError(e);
    } finally {
      this.loading = false;
    }
  }

  @action
  startNew() {
    this.editingId = "new";
    this.newTitle = "";
    this.newNotes = "";
    this.newUploadId = null;
  }

  @action
  cancelEdit() {
    this.editingId = null;
  }

  @action
  async saveNew() {
    try {
      const created = await ajax(this.apiBase, {
        type: "POST",
        data: {
          title: this.newTitle,
          notes: this.newNotes,
          upload_id: this.newUploadId,
          position: 0,
        },
      });
      this.items = [created, ...this.items];
      this.editingId = null;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async remove(item) {
    try {
      await ajax(`${this.apiBase}/${item.id}`, { type: "DELETE" });
      this.items = this.items.filter((it) => it.id !== item.id);
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  async upload(file) {
    try {
      if (!file) {
        return;
      }
      const uploader = new Uploader(file, { type: "composer" });
      const upload = await uploader.upload();
      this.newUploadId = upload.id;
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  onFileChange(e) {
    this.upload(e?.target?.files?.[0]);
  }
}

