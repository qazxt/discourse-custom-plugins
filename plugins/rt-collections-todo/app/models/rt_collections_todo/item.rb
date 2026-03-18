# frozen_string_literal: true

module ::RtCollectionsTodo
  class Item < ActiveRecord::Base
    self.table_name = "rt_collections_todo_items"

    belongs_to :user
    belongs_to :upload, optional: true

    # Rails 8 不再支持 enum 的 keyword 参数写法（enum list_type: {...}）
    enum :list_type, { collection: 0, todo: 1 }

    validates :user_id, presence: true
    validates :list_type, presence: true
    validates :title, presence: true, length: { maximum: 200 }
    validates :position, numericality: { only_integer: true }
  end
end

