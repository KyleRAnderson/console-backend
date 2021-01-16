# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1', '>= 6.1.1'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Devise for user authentication
gem 'devise', '~> 4.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# ActiveRecord Import for bulk inserting records
gem 'activerecord-import', '~> 1.0.6'

# Search engine
gem 'pg_search', '~> 2.3', '>= 2.3.2'

# User autorization and permissions
gem 'pundit', '~> 2.1.0'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

gem 'will_paginate', '~> 3.1'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]

  # Simple configuration of environment variables
  gem 'dotenv-rails', '~> 2.7.6'

  gem 'faker', git: 'https://github.com/faker-ruby/faker.git', branch: 'master'

  # RSpec for testing
  gem 'rspec-rails', '~> 4.0'
end

group :production do
  # Google cloud storage
  gem 'google-cloud-storage', '~> 1.26', '>= 1.26.2'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '~> 3.4'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  # Factory library for tests.
  gem 'factory_bot_rails', '~> 5.2.0'
  # RSpec helpers for pundit
  gem 'pundit-matchers', '~> 1.6.0'

  # Allows formatting RSpec test results with JUnit XML.
  gem 'rspec_junit_formatter', '~> 0.4.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# Handles cross-origin resource sharing
gem 'rack-cors', '~> 1.1'
