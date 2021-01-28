# See https://github.com/cyu/rack-cors, https://guides.rubyonrails.org/configuring.html#configuring-middleware
allowed_host = Rails.application.config.frontend_host_url
if allowed_host.present?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins allowed_host
      resource '*',
               headers: :any,
               methods: [:get, :post, :patch, :put, :delete, :options, :head],
               credentials: true # Allow secure cookie access
    end
    Rails.application.config.hosts << allowed_host
  end
end