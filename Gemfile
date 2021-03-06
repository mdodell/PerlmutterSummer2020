source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0.2', '>= 6.0.2.2'
# For multi-language application
gem 'rails-i18n'
# Use postgresql as the database for Active Record
gem 'pg', '>= 0.18', '< 2.0'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 4.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Devise is used for user login and authentication
gem 'devise'
# DotENV is used to keep track of environmental variables locally for development/test. Heroku config variables are used for production and staging.
gem 'dotenv-rails'
# Kaminari is for pagination
gem 'kaminari'
# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0", :require => ["redis", "redis/connection/hiredis"]
gem "hiredis"
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'
# Use Twilio for text/call capabilities
gem 'twilio-ruby', '~> 5.35.0'
# Use bootstrap_form for nicely formatted forms with error handling
gem "bootstrap_form", "~> 4.0"
# For displaying SVG images/icons
gem 'inline_svg'
# For adding emoji support
gem 'twemoji'
# For icons
gem 'font-awesome-sass', '~> 5.13.0'
# For profile photos
gem 'gravatar_image_tag'
# For graphing
gem 'chartkick'
# For grouping models by time
gem 'groupdate'
# Use Active Storage variant
# gem 'image_processing', '~> 1.2'
# Use Faker for seeded records
gem 'faker'
# For the initializer
gem "tty-prompt"
gem "tty-command"
gem "tty-file"
gem "tty-box"
gem "tty-config"
gem "tty-link"
gem "tty-spinner"
gem "platform-api"
gem "git"
gem "rename"
gem "rmagick"

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # For generating fake data for testing
  gem 'faker'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'ngrok-tunnel'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 2.15'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'
  gem "minitest-rails", "~> 6.0.0"
  gem 'minitest-reporters', '>= 0.5.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem "stimulus_reflex", "~> 3.2"
