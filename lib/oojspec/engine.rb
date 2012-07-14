require "rails-sandbox-assets"

module Oojspec
  class OojspecFilter
    def self.filter(controller)
      controller.template = 'oojspec/runner' if controller.params[:path].try :start_with?, 'oojspec'
    end
  end

  class Engine < ::Rails::Engine
    initializer 'sandbox_assets.oojspec' do |app|
      unless app.config.sandbox_assets.template == 'oojspec/runner'
        SandboxAssets::BaseController.prepend_before_filter OojspecFilter
      end
    end
  end
end
