require "rails-sandbox-assets"
require 'rack/file'

module Oojspec
  class OojspecFilter
    def self.before(controller)
      return unless controller.params[:path].try :start_with?, 'oojspec'
      controller.template = 'oojspec/runner'
      controller.iframe_template = 'oojspec/iframe'
    end
  end

  class Engine < ::Rails::Engine
    static_path = File.join root, 'dist'
    initializer 'sandbox_assets.oojspec' do |app|
      unless app.config.sandbox_assets.template == 'oojspec/runner'
        SandboxAssets::BaseController.prepend_before_filter OojspecFilter
      end

      # we skip Sprockets management to support source-maps properly. Sprockets will add an
      # additional semi-colon to the end of the assets.
      ::SandboxAssets::Engine.routes.prepend do
        mount Rack::File.new(static_path) => '/static', as: :oojspec_static
      end
    end
  end
end
