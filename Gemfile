# frozen_string_literal: true

source 'https://rubygems.org'

# URL encoding
gem 'addressable', '~> 2.8'
# Amazon S3 SDK
gem 'aws-sdk-s3', '~> 1'
# gem 'aws-sdk-s3', git: 'https://github.com/elohanlon/aws-sdk-ruby',
#  branch: 's3_allow_custom_multipart_part_size_during_object_upload', glob: 'gems/aws-sdk-s3/*.gemspec'
# Additional gem enabling the AWS SDK to calculate CRC32C checksums
gem 'aws-crt', '~> 0.2.0'
# For file type determination
gem 'best_type', '~> 1.0'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false
# Add CRC32C support to the Ruby Digest module
gem 'digest-crc', '~> 0.6.5'
# Google Cloud Storage SDK
gem 'google-cloud-storage', '~> 1.49'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem 'jbuilder'
# Use mysql as a database option for Active Record
gem 'mysql2', '~> 0.5.6'
# Use the Puma web server for local development [https://github.com/puma/puma]
gem 'puma', '~> 6.0'
# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 7.1.3', '>= 7.1.3.2'
# Rainbow for text coloring
gem 'rainbow', '~> 3.0'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.8' # NOTE: Updating the redis gem to v5 breaks the current redis namespace setup
# For namespacing the Redis keys used by resque
gem 'redis-namespace', '~> 1.11'
# Resque for queued jobs
gem 'resque', '~> 2.6'
# Resque for retrying code after errors
gem 'retriable', '~> 3.1'
# We don't actually use sinatra directly, but it is used by resque.
# We need to pin to 3.x because 4.x introduces a conflict.
# The line below can be removed if resque ever stops requiring sinatra.
gem 'sinatra', '~> 3.0'
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Unicode to ASCII transliteration [https://rubygems.org/gems/stringex/]
gem 'stringex', '~> 2.8', '>= 2.8.6'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Use devise and omniauth for authentication
gem 'devise'
gem 'omniauth'
gem 'omniauth-cul', '~> 0.2.0'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows]
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 1.4'
  # Rubocul for linting
  gem 'rubocul', '~> 4.0.11'
  # gem 'rubocul', path: '../rubocul'
end

group :development do
  # Use Capistrano for deployment
  gem 'capistrano', '~> 3.18.0', require: false
  gem 'capistrano-cul', require: false
  gem 'capistrano-passenger', '~> 0.1', require: false
  gem 'capistrano-rails', '~> 1.4', require: false

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"

  # simplecov for test coverage
  gem 'simplecov', '~> 0.22', require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
end
