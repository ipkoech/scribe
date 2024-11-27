class OtpVerificationMiddleware
  # Routes for which OTP verification will be skipped
  # SKIP_OTP_VERIFICATION_PATHS = ['/otp/resend', '/otp/verify', 'login', 'forgot', '/reset','/drafts/callback']
  SKIP_OTP_VERIFICATION_PATHS = [ "/otp/resend", "/otp/verify", "/login", "forgot", "password/reset", "/drafts/callback" ]

  def initialize(app)
    @app = app
  end
  def call(env)
    request = Rack::Request.new(env)
    token = request.env["HTTP_AUTHORIZATION"]&.split(" ")&.last
    if token && !skip_otp_verification?(request.path_info)
      payload, _header = decode_jwt(token)
      # If payload is nil, the token couldn't be decoded. Proceed with the request,
      # letting downstream parts of the application handle unauthorized access.
      if payload.nil? || user_otp_valid?(payload)
        @app.call(env) # Proceed with the request if OTP is valid or token is invalid
      else
        # Return a 403 Forbidden response if OTP verification specifically fails
        [ 403, { "Content-Type" => "application/json" }, [ { error: "OTP verification failed or required.", code: "OTP_REQUIRED" }.to_json ] ]
      end
    else
      @app.call(env) # Proceed with the request if there is no token or if OTP verification is skipped
    end
  end
  private
  def decode_jwt(token)
    # Decode the JWT token to extract the payload.
    JWT.decode(token, Rails.application.credentials.jwt_secret_key)
  rescue JWT::DecodeError
    nil # Token is invalid, return nil to let other parts of the app handle it
  end
  def user_otp_valid?(payload)
    # Find the user
    user = User.find_by(id: payload["sub"])
    # If the user can't be found, return true to not block the request here
    return true unless user
    # Proceed if OTP is not enabled for the user
    return true unless user.otp_enabled
    # Verify OTP
    payload["otp_verified"] == true
  end

  def skip_otp_verification?(path)
    SKIP_OTP_VERIFICATION_PATHS.include?(path)
    # Extract the path without query parameters
    clean_path = path.split("?").first
    SKIP_OTP_VERIFICATION_PATHS.include?(clean_path)
  end
end
