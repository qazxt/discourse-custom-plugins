# frozen_string_literal: true

RtCollectionsTodo::Engine.routes.draw do
  # 默认 :segment 不含 "."，会被当成 optional format；用户名可能含 "." 等，需显式约束。
  constraints username: %r{[^/]+}, list_type: /collection|todo/ do
    get "/u/:username/:list_type" => "items#index"
    post "/u/:username/:list_type" => "items#create"
    put "/u/:username/:list_type/:id" => "items#update"
    delete "/u/:username/:list_type/:id" => "items#destroy"
  end
end
