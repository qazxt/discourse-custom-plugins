RtCollectionsTodo::Engine.routes.draw do
  get "/u/:username/:list_type" => "items#index"
  post "/u/:username/:list_type" => "items#create"
  put "/u/:username/:list_type/:id" => "items#update"
  delete "/u/:username/:list_type/:id" => "items#destroy"
end

