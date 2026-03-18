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
    this.#load();
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

  async #load() {
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

<template>
  <section class="rt-collections-todo">
    <header class="rt-collections-todo__header">
      <h2 class="rt-collections-todo__title">{{this.headerTitle}}</h2>
      {{#if this.canEdit}}
        <DButton
          @label="rt_collections_todo.add_item"
          @action={{this.startNew}}
          class="btn-primary"
        />
      {{/if}}
    </header>

    {{#if this.loading}}
      <p class="rt-collections-todo__loading">{{i18n "loading"}}</p>
    {{else}}
      {{#if (and this.canEdit (eq this.editingId "new"))}}
        <div class="rt-collections-todo__editor">
          <label>
            {{i18n "rt_collections_todo.product_name"}}
            <Input @value={{this.newTitle}} />
          </label>
          <label>
            {{i18n "rt_collections_todo.notes"}}
            <Textarea @value={{this.newNotes}} />
          </label>
          <label>
            {{i18n "rt_collections_todo.product_photo"}}
            <input
              type="file"
              accept="image/*"
              {{on "change" this.onFileChange}}
            />
          </label>

          <div class="rt-collections-todo__editor-actions">
            <DButton @label="save" @action={{this.saveNew}} class="btn-primary" />
            <DButton @label="cancel" @action={{this.cancelEdit}} />
          </div>
        </div>
      {{/if}}

      <ul class="rt-collections-todo__list">
        {{#each this.items as |item|}}
          <li class="rt-collections-todo__item">
            {{#if item.image_url}}
              <img class="rt-collections-todo__item-image" src={{item.image_url}} alt="" />
            {{/if}}
            <div class="rt-collections-todo__item-body">
              <div class="rt-collections-todo__item-title">{{item.title}}</div>
              {{#if item.notes}}
                <div class="rt-collections-todo__item-notes">{{item.notes}}</div>
              {{/if}}
            </div>
            {{#if this.canEdit}}
              <DButton
                @icon="trash-alt"
                @title="delete"
                @action={{fn this.remove item}}
                class="btn-danger"
              />
            {{/if}}
          </li>
        {{/each}}
      </ul>
    {{/if}}
  </section>
</template>

