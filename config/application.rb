require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HuntConsole
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # API Only application. This should remain at the top
    config.api_only = false # FIXME revert to true one day when the tests start working again

    # Add cookie middleware (included by default in non api_only applications)
    # This also configures session_options for use below
    config.session_store :cookie_store, key: '_interslice_session'

    # See: https://github.com/rails/rails/blob/3c9d7a268f325f5cc6ab1ab49aed6f52e4c4f631/guides/source/api_app.md#using-session-middlewares.
    # Required for all session management (regardless of session_store)
    config.middleware.use ActionDispatch::Cookies
    # config.session_options[:secure] = Rails.env.production? # TODO make sure that asserting this config in production.rb works with the following line.
    config.middleware.use config.session_store, config.session_options

    # Add session middleware (included by default in non api_only applications)
    config.middleware.use ActionDispatch::Session::CookieStore
    # TODO not sure if it's helpful, from https://stackoverflow.com/a/61238872/7309070
    config.middleware.insert_after(ActionDispatch::Cookies, ActionDispatch::Session::CookieStore)

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Don't generate system test files.
    config.generators.system_tests = nil

    # # By default, don't allow any CORS
    config.allowed_cors_origins = nil # TODO not sure about adding my own configs like this
  end
end
