require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'action_view/railtie'
require 'action_cable/engine'
# See https://github.com/fgrehm/letter_opener_web/issues/46#issuecomment-273975173 for an error that I was getting while this
# line was commented out.
require 'sprockets/railtie'
require 'rails/test_unit/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module HuntConsole
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # API Only application. This should remain near the top (below the load_defaults of course)
    # See also https://guides.rubyonrails.org/api_app.html#changing-an-existing-application for
    # some of what needs to be done for api_only apps.
    config.api_only = true

    # See: https://github.com/rails/rails/blob/3c9d7a268f325f5cc6ab1ab49aed6f52e4c4f631/guides/source/api_app.md#using-session-middlewares.
    # Add cookie middleware (included by default in non api_only applications)
    # See the relevant section of https://guides.rubyonrails.org/v6.1/configuring.html#rails-general-configuration
    # This also configures session_options for use below
    config.session_store :cookie_store

    # Required for all session management (regardless of session_store)
    config.middleware.use ActionDispatch::Cookies
    # Enable HTTPS-only session cookies in production
    config.session_options[:secure] = Rails.env.production?
    config.middleware.use config.session_store, config.session_options

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
