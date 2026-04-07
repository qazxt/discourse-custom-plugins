import Component from "@glimmer/component";
import { action } from "@ember/object";
import { tracked } from "@glimmer/tracking";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { service } from "@ember/service";
import { i18n } from "discourse-i18n";

export default class RtCollectionsTodoList extends Component {
  @service currentUser;
  @service siteSettings;
  @tracked items = [];
  @tracked loading = true;
  @tracked editingId = null;
  @tracked newTitle = "";
  @tracked newNotes = "";
  @tracked newUploadId = null;
  @tracked editTitle = "";
  @tracked editNotes = "";
  @tracked editUploadId = null;

  constructor() {
    super(...arguments);
    this.load();
  }

  get canEdit() {
    return this.currentUser?.username === this.args.user?.username;
  }

  get headerTitle() {
    return this.args.listType === "collection"
      ? i18n("rt_collections_todo.my_collection")
      : i18n("rt_collections_todo.to_do_list");
  }

  get apiBase() {
    const u = this.args.user?.username;
    if (!u) {
      return "";
    }
    return `/rt-collections-todo/u/${u}/${this.args.listType}`;
  }

  get notesMaxLength() {
    const value = Number(this.siteSettings.rt_collections_todo_notes_max_length);
    return Number.isFinite(value) && value > 0 ? value : 250;
  }

  async load() {
    if (!this.args.user?.username) {
      this.loading = false;
      return;
    }
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
    this.editTitle = "";
    this.editNotes = "";
    this.editUploadId = null;
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
      // 新增接口在不同 Discourse 版本可能返回 root 包装对象（而列表渲染期望扁平 item）；
      // 直接 reload 可统一数据形态，避免“刚新增时图片不显示/删除按钮错位，刷新后恢复”的瞬态错乱。
      const normalized = created?.rt_collections_todo_item || created?.item || created;
      if (normalized?.id) {
        this.items = [normalized, ...this.items];
      }
      await this.load();
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
  startEdit(item) {
    this.editingId = item.id;
    this.editTitle = item.title || "";
    this.editNotes = item.notes || "";
    this.editUploadId = item.upload_id || null;
  }

  @action
  async saveEdit(item) {
    try {
      await ajax(`${this.apiBase}/${item.id}`, {
        type: "PUT",
        data: {
          title: this.editTitle,
          notes: this.editNotes,
          upload_id: this.editUploadId,
        },
      });
      await this.load();
      this.cancelEdit();
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
      // Discourse v2026+ 已移除 discourse/lib/uploader，走标准 POST /uploads.json
      const data = new FormData();
      data.append("file", file);
      data.append("upload_type", "composer");
      const upload = await ajax("/uploads.json", {
        type: "POST",
        data,
        processData: false,
        contentType: false,
      });
      if (this.editingId === "new") {
        this.newUploadId = upload.id;
      } else if (this.editingId) {
        this.editUploadId = upload.id;
      }
    } catch (e) {
      popupAjaxError(e);
    }
  }

  @action
  onFileChange(e) {
    this.upload(e?.target?.files?.[0]);
  }
}

