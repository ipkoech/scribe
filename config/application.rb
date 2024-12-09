require_relative "boot"
require "rails/all"
require_relative "../lib/otp_verification_middleware"

Bundler.require(*Rails.groups)
module Scribe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2
    config.autoload_lib(ignore: %w[assets tasks])
    # Middleware configuration
    # config.middleware.use OtpVerificationMiddleware
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq
  end
end
