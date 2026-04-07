# frozen_string_literal: true

module ::RtCollectionsTodo
  class Item < ActiveRecord::Base
    self.table_name = "rt_collections_todo_items"

    belongs_to :user
    belongs_to :upload, optional: true

    # Rails 8 不再支持 enum 的 keyword 参数写法（enum list_type: {...}）
    enum :list_type, { collection: 0, todo: 1 }

    def self.notes_max_for_validation
      n = SiteSetting.rt_collections_todo_notes_max_length.to_i
      n > 0 ? n : 250
    end

    validates :user_id, presence: true
    validates :list_type, presence: true
    validates :title, presence: true, length: { maximum: 200 }
    validates :notes,
              length: { maximum: ->(_) { Item.notes_max_for_validation } },
              allow_blank: true
    validates :position, numericality: { only_integer: true }
  end
end

