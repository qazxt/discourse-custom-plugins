# frozen_string_literal: true

# name: rt-collections-todo
# about: Add My Collection and To do list on user profiles
# version: 0.1.0
# authors: rt
# url: https://example.invalid/rt-collections-todo

enabled_site_setting :rt_collections_todo_enabled

register_asset "stylesheets/rt-collections-todo.scss"

module ::RtCollectionsTodo
  PLUGIN_NAME = "rt-collections-todo"

  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace RtCollectionsTodo
  end
end

require_relative "lib/rt_collections_todo/engine"

after_initialize do
  module ::RtCollectionsTodo
    class Error < StandardError; end
  end

  require_relative "app/models/rt_collections_todo/item"
  require_relative "app/controllers/rt_collections_todo/items_controller"
  require_relative "app/serializers/rt_collections_todo/item_serializer"
  require_relative "app/serializers/rt_collections_todo/items_list_serializer"

  Discourse::Application.routes.append do
    mount ::RtCollectionsTodo::Engine, at: "/rt-collections-todo"
  end
end

