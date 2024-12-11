source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.2.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

gem "devise"
gem "rack-attack"

gem "redis"
gem "diff-lcs"
gem "whenever", require: false
gem "sidekiq"

# html conflicts

# geo libraries
gem "geocoder"  # For geocoding and simple distance calculations
gem "rgeo"  # For advanced geospatial data types and calculations

gem "devise-jwt"

gem "kaminari"

gem "ransack"
gem "dotenv-rails", groups: [:development, :test]

gem "faker" # TODO: remove in prod

gem "pundit", "~> 2.3"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
gem "rack-cors"
gem "rqrcode"
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Azure Blob Storage
gem "azure-blob"

gem "mime-types"

# Markdown conversion
gem "redcarpet"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end
