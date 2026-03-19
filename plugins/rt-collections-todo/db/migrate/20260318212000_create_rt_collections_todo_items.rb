# frozen_string_literal: true

class CreateRtCollectionsTodoItems < ActiveRecord::Migration[7.0]
  def change
    create_table :rt_collections_todo_items do |t|
      t.integer :user_id, null: false
      t.integer :list_type, null: false
      t.string :title, null: false
      t.integer :upload_id
      t.text :notes
      t.integer :position, null: false, default: 0
      t.timestamps null: false
    end

    add_index :rt_collections_todo_items,
              %i[user_id list_type position],
              name: "idx_rt_ctodo_user_list_pos"
    add_index :rt_collections_todo_items, :upload_id
  end
end

