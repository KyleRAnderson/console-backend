# Rails API mode setup

- [Pragmatic studio's excellent guide][pragmatic-studio-guide] for a lot of the stuff I had to do.
- [Official Rails guides](https://guides.rubyonrails.org/api_app.html#changing-an-existing-application)
- [Devise Stuff](https://github.com/heartcombo/devise/issues/4997)

To see what modules are included in `ActionController::API` versus `ActionController::Base` in the rails console:

```ruby
ActionController::Base.ancestors # Lists the module ancestors of ActionController::Base
ActionController::API.ancestors # Lists the module ancestors of ActionController::API
```

## Cross-Origin resource sharing (CORS)

- For configuring middleware, and the extra stuff required to whitelist certain origins:
  https://guides.rubyonrails.org/configuring.html#configuring-middleware
- [Rack-CORS](https://github.com/cyu/rack-cors)
- The [Pragmatic studio][pragmatic-studio-guide] described the configuration as well.

# Binstubs

Binstubs are executable files for running various ruby binaries (such as `rails`, `bundle`, `rspec`). They are useful
because they ensure that the correct version for the app can be used, much like what `bundle exec` (see a [discussion on the difference](https://stackoverflow.com/questions/44688321/should-i-use-bundle-exec-or-rails-binstubs)).

Binstubs can be generated like this:

```bash
# Get bundle to generate binstubs
bundle exec rake app:update:bin
# Add binstubs for the gems that you want, such as rspec
bundle binstubs rspec-core
# Add spring to these binstubs
spring binstub --all
```

[pragmatic-studio-guide]: https://pragmaticstudio.com/tutorials/rails-session-cookies-for-api-authentication

# Issues along the way

## Upgrading to Rails 6.1

Taking a look at the [update notes](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-6-0-to-rails-6-1), it didn't seem like I would have much of anything to do.
However, I started to encounter issues with active storage methods. I discovered [this post](https://stackoverflow.com/questions/58373159/unknown-attribute-service-name-for-activestorageblob) and that led me to this simple solution:

```bash
rails active_storage:update
rails db:migrate
RAILS_ENV=test rails db:migrate # Migrate the test database as well
```

# Various hard to find Rails topics

[What does respond_to do?](https://api.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to)
