# frozen_string_literal: true

require "rails_helper"

RSpec.describe RtCollectionsTodo::ItemsController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other) { Fabricate(:user) }

  before do
    SiteSetting.rt_collections_todo_enabled = true
  end

  it "allows owner to create and others to read" do
    sign_in(user)

    post "/rt-collections-todo/u/#{user.username}/collection",
         params: { title: "Kit A", notes: "note", position: 0 }
    expect(response.status).to eq(200)

    sign_out
    get "/rt-collections-todo/u/#{user.username}/collection"
    expect(response.status).to eq(200)
  end

  it "blocks unauthenticated edits" do
    item = RtCollectionsTodo::Item.create!(user_id: user.id, list_type: RtCollectionsTodo::Item.list_types[:collection], title: "X", position: 0)

    sign_out
    put "/rt-collections-todo/u/#{user.username}/collection/#{item.id}", params: { title: "Y" }
    expect(item.reload.title).to eq("X")
  end
end

