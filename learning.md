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

**What I should've done first** was run the `rails app:update` task, and then gone through the changes
that it introduced, and seen if they were good. I did eventually do this, just after the stuff below.
As part of this, it overwrote the binstubs, so I fixed them with the steps described in the [binstubs](#binstubs) section.

Taking a look at the [update notes](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#upgrading-from-rails-6-0-to-rails-6-1), it didn't seem like I would have much of anything to do.
However, I started to encounter issues with active storage methods. I discovered [this post](https://stackoverflow.com/questions/58373159/unknown-attribute-service-name-for-activestorageblob) and that led me to this simple solution:

```bash
rails active_storage:update
rails db:migrate
RAILS_ENV=test rails db:migrate # Migrate the test database as well
```

### Problems with `fixture_file_upload`

I was getting the following when running the unit tests:

```
NoMethodError:
       undefined method `file_fixture_path' for RSpec::Rails::FixtureFileUploadSupport::RailsFixtureFileWrapper:Class
       Did you mean?  fixture_path
```

The problem was that the `rspec-rails` gem (version 4.0.2) didn't fully support Rails 6.1. The workaround was to replace usages of `fixture_file_upload` with
`Rack::Test::UploadedFile.new(Pathname.new(file_fixture_path).join(path), mime_type, false)`. This was discovered after looking at the [source code for `fixture_file_upload`](https://api.rubyonrails.org/classes/ActionDispatch/TestProcess/FixtureFile.html#method-i-fixture_file_upload).

Links:

- [Issue on GitHub](https://github.com/rspec/rspec-rails/issues/2439).
- [Someone else with the same issue](https://github.com/egiurleo/fixture-file-upload-test/commit/e2524d11220bb8169b42aaa5235d214ba8a1dd56).

## `Undefined method []=` after setting `config.api_only = true`

I was having trouble in all tests that used the Devise session helpers `sign_in` after enabling api_only for the application.
After several days, I found [documentation on how to fix the issue](https://github.com/heartcombo/devise#testing), as well as
a [GitHub ticket write-up about it](https://github.com/heartcombo/devise/issues/4696).
The fix is just to re-order the insertion of middleware so that the `Warden::Manager` is inserted after
`ActionDispatch::Cookies` and `ActionDispatch::Session::CookieStore`.

## Cookies

- [Great explanation on SameSite cookies](https://web.dev/samesite-cookies-explained/)
- [Mozilla's public suffix list](https://publicsuffix.org/list/), which denotes sites which do not
  allow cookies to be set regularly. `herokuapp.com` is one of them, which might explain all the issues we were having.

# Various hard to find Rails topics

[What does respond_to do?](https://api.rubyonrails.org/classes/ActionController/MimeResponds.html#method-i-respond_to)

# Security

[Good Stack Overflow post on CSRF protection](https://stackoverflow.com/questions/20504846/why-is-it-common-to-put-csrf-prevention-tokens-in-cookies).
