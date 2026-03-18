# frozen_string_literal: true

module ::RtLuckySpin
  class Engine < ::Rails::Engine
    engine_name ::RtLuckySpin::PLUGIN_NAME
    isolate_namespace RtLuckySpin
  end
end

