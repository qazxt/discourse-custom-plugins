# frozen_string_literal: true

module ::RtCollectionsTodo
  class ItemsListSerializer < ApplicationSerializer
    attributes :username, :list_type
    has_many :items, serializer: RtCollectionsTodo::ItemSerializer

    def items
      object[:items]
    end

    def username
      object[:username]
    end

    def list_type
      object[:list_type]
    end
  end
end

