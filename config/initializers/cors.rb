# frozen_string_literal: true

# See https://github.com/cyu/rack-cors, https://guides.rubyonrails.org/configuring.html#configuring-middleware
allowed_host = Rails.application.config.frontend_host_url
if allowed_host.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    puts "Allowing host: #{allowed_host}" # FIXME REMOVE
    allow do
      origins allowed_host
      resource '*',
               headers: :any,
               methods: [:get, :post, :patch, :put, :delete, :options, :head],
               credentials: true # Allow secure cookie access
    end
  end
end
