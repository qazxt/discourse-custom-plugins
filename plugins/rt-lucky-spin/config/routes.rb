RtLuckySpin::Engine.routes.draw do
  get "/state" => "spins#state"
  post "/spin" => "spins#spin"
  get "/history" => "spins#history"

  get "/admin/weekly" => "admin#weekly"
  put "/admin/weekly/:id/shipping" => "admin#update_shipping"
end

