# frozen_string_literal: true

module ::RtCollectionsTodo
  class ItemsController < ::ApplicationController
    requires_plugin ::RtCollectionsTodo::PLUGIN_NAME

    before_action :ensure_enabled
    before_action :load_target_user
    before_action :load_list_type

    def index
      guardian.ensure_can_see_profile!(@target_user)

      items =
        RtCollectionsTodo::Item
          .where(user_id: @target_user.id, list_type: RtCollectionsTodo::Item.list_types[@list_type])
          .order(:position, :id)

      render_serialized(
        { username: @target_user.username, list_type: @list_type, items: items },
        RtCollectionsTodo::ItemsListSerializer
      )
    end

    def create
      ensure_can_edit!

      item =
        RtCollectionsTodo::Item.create!(
          user_id: @target_user.id,
          list_type: RtCollectionsTodo::Item.list_types[@list_type],
          title: params.require(:title),
          notes: params[:notes],
          upload_id: params[:upload_id],
          position: (params[:position] || 0).to_i
        )

      render_serialized(item, RtCollectionsTodo::ItemSerializer)
    end

    def update
      ensure_can_edit!

      item = find_item!

      item.update!(
        title: (params[:title] if params.key?(:title)),
        notes: (params[:notes] if params.key?(:notes)),
        upload_id: (params[:upload_id] if params.key?(:upload_id)),
        position: (params[:position].to_i if params.key?(:position))
      )

      render_serialized(item, RtCollectionsTodo::ItemSerializer)
    end

    def destroy
      ensure_can_edit!
      find_item!.destroy!
      render json: success_json
    end

    private

    def ensure_enabled
      raise Discourse::NotFound unless SiteSetting.rt_collections_todo_enabled
    end

    def load_target_user
      @target_user = User.find_by(username: params[:username])
      raise Discourse::NotFound if @target_user.blank?
    end

    def load_list_type
      @list_type = params[:list_type].to_s
      raise Discourse::NotFound unless RtCollectionsTodo::Item.list_types.key?(@list_type)
    end

    def ensure_can_edit!
      guardian.ensure_authenticated!
      raise Discourse::InvalidAccess unless current_user.id == @target_user.id || guardian.is_admin?
    end

    def find_item!
      item = RtCollectionsTodo::Item.find_by(id: params[:id], user_id: @target_user.id)
      raise Discourse::NotFound if item.blank?
      item
    end
  end
end

