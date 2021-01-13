# See https://github.com/cyu/rack-cors, https://guides.rubyonrails.org/configuring.html#configuring-middleware
allowed_hosts = Rails.application.config.allowed_cors_origins
if allowed_hosts.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins *allowed_hosts
      resource '*',
               headers: :any,
               methods: [:get, :post, :patch, :put, :delete, :options, :head],
               credentials: true # Allow secure cookie access
    end
    #   Rails.application.config.hosts.concat(allowed_hosts) # TODO add back once you get it working
  end
end
