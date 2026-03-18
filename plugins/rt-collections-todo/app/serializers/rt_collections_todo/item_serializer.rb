# frozen_string_literal: true

module ::RtCollectionsTodo
  class ItemSerializer < ApplicationSerializer
    attributes :id,
               :list_type,
               :title,
               :notes,
               :position,
               :created_at,
               :updated_at,
               :upload_id,
               :image_url

    def image_url
      return nil if object.upload_id.blank?
      Upload.find_by(id: object.upload_id)&.url
    end
  end
end

