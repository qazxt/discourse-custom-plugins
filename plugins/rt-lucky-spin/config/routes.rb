RtLuckySpin::Engine.routes.draw do
  get "/state" => "spins#state", defaults: { format: :json }
  post "/spin" => "spins#spin", defaults: { format: :json }
  get "/history" => "spins#history", defaults: { format: :json }

  get "/admin/weekly" => "admin#weekly", defaults: { format: :json }
  put "/admin/weekly/:id/shipping" => "admin#update_shipping"
end

