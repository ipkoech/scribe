require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true


# Do not eager load code on boot.
config.eager_load = false

# Show full error reports.
config.consider_all_requests_local = true

config.hosts << /.*\.ngrok-free\.app/

# Enable server timing
config.server_timing = true
config.action_cable.allowed_request_origins = [ "http://localhost:4200" ]
Rails.application.routes.default_url_options[:host] = "localhost:3000"

# config.action_cable.allowed_request_origins = ['https://rnkyg-41-90-184-164.a.free.pinggy.link']
#  Default url options in your environments files
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: "smtp.ionos.com",
  port: 587,
  domain: "smtp.ionos.com",
  user_name: "accounts@egric.com",
  password: "Accounts@egric12",
  authentication: "plain",
  enable_starttls_auto: true
}


# Enable/disable caching. By default caching is disabled.
# Run rails dev:cache to toggle caching.
if Rails.root.join("tmp/caching-dev.txt").exist?
  config.cache_store = :memory_store
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{2.days.to_i}"
  }
else
  config.action_controller.perform_caching = false

  config.cache_store = :null_store
end

# Store uploaded files on the local file system (see config/storage.yml for options).
config.active_storage.service = :azure

# Don't care if the mailer can't send.
config.action_mailer.raise_delivery_errors = true

config.action_mailer.perform_caching = false

# Print deprecation notices to the Rails logger.
config.active_support.deprecation = :log

# Raise exceptions for disallowed deprecations.
config.active_support.disallowed_deprecation = :raise

# Tell Active Support which deprecation messages to disallow.
config.active_support.disallowed_deprecation_warnings = []

# Raise an error on page load if there are pending migrations.
# config.active_record.migration_error = :page_load
config.active_record.migration_error = false

# Highlight code that triggered database queries in logs.
config.active_record.verbose_query_logs = true

# Highlight code that enqueued background job in logs.
config.active_job.verbose_enqueue_logs = true

# Raises error for missing translations.
# config.i18n.raise_on_missing_translations = true

# Annotate rendered view with file names.
# config.action_view.annotate_rendered_view_with_filenames = true

# Uncomment if you wish to allow Action Cable access from any origin.
# config.action_cable.disable_request_forgery_protection = true
# config.action_cable.allowed_request_origins = ['https://rnkyg-41-90-184-164.a.free.pinggy.link']
config.action_cable.allowed_request_origins = [ "http://localhost:4200" ]

# Raise error when a before_action's only/except options reference missing actions
config.action_controller.raise_on_missing_callback_actions = true

# active_storage config
config.active_storage.service = :local
end
