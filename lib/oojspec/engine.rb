require "rails-sandbox-assets"

module Oojspec
  class OojspecFilter
    def self.before(controller)
      return unless controller.params[:path].try :start_with?, 'oojspec'
      controller.template = 'oojspec/runner'
      controller.iframe_template = 'oojspec/iframe'
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
