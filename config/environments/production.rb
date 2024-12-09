require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false
  config.active_job.queue_adapter = :sidekiq

  # Set up Action Mailer and Action Cable for the correct domains.
  config.action_mailer.default_url_options = { host: "api.instascribe.revcat.cloud", protocol: "https" }
  Rails.application.routes.default_url_options[:host] = "api.instascribe.revcat.cloud"
  config.action_cable.allowed_request_origins = ["https://instascribe.revcat.cloud", "https://www.instascribe.revcat.cloud"]

  # Action Mailer SMTP settings
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: "smtp.ionos.com",
    port: 587,
    domain: "smtp.ionos.com",
    user_name: "instascribe@revcat.cloud",
    password: "InstaTesting@24",
    authentication: "plain",
    enable_starttls_auto: true,
  }

  # Ensure SSL is enforced for secure communication
  config.force_ssl = true

  # Disable serving static files from `public/`, relying on NGINX/Apache.
  config.public_file_server.enabled = false

  # Store uploaded files on the local file system.
  config.active_storage.service = :local

  # Force all access to the app over SSL and add security headers.
  config.force_ssl = true
  config.action_dispatch.default_headers.merge!({
    "X-Frame-Options" => "DENY",
    "X-Content-Type-Options" => "nosniff",
    "X-XSS-Protection" => "1; mode=block",
  })

  # Log to STDOUT by default
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id, :remote_ip]

  # Set log level
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  config.logger = Logger.new(Rails.root.join("log", "production.log"), 5, 50.megabytes)

  # Action Mailer caching settings
  config.action_mailer.perform_caching = false

  # Enable locale fallbacks for I18n
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # DNS rebinding protection and Host header attacks.
  config.hosts = [
    "api.instascribe.revcat.cloud",
    "instascribe.revcat.cloud",
    "www.instascribe.revcat.cloud",
    "34.72.37.133",
    "172.205.250.247"
  ]
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
