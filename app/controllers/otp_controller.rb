class OtpController < ApplicationController
  before_action :authenticate_user!, only: [ :verify, :resend ]

  before_action :authorize_admin!, only: [ :enable_two_factor_for_user, :disable_two_factor_for_user ]

  def send_otp
    params.require(:email)
    @user = User.find_by(email: params[:email])

    if @user
      @user.generate_otp!
      UserMailer.otp_sent(@user).deliver_later
      render json: { message: "OTP sent successfully." }, status: :ok
    else
      render json: { error: "User not found" }, status: :not_found
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end


  def resend
      current_user.generate_otp!
      UserMailer.otp_sent(current_user).deliver_later

      render json: { message: "OTP sent successfully." }, status: :ok
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def verify
    unless params[:code].present?
      return render json: { errors: { code: [ "OTP code is required" ] } }, status: :unprocessable_entity
    end

    if current_user.verify_otp?(params[:code])
      current_user.clear_otp! # Clear the OTP after successful verification

      # Generate a new token with otp_verified set to true
      new_token = generate_jwt_for_user(current_user)

      # Invalidate old token
      invalidate_token(request.headers["Authorization"])

      # Sign out the user
      sign_out(current_user)

      # Include the new token in the Authorization header of the response
      response.set_header("Authorization", "Bearer #{new_token}")

      render json: { message: "OTP verified successfully." }, status: :ok
    else
      # Invalid OTP code
      render json: { errors: { code: [ "Invalid OTP code" ] } }, status: :unprocessable_entity
    end
  end

  def enable_two_factor_for_user
    # Ensure the admin has provided the user ID
    user_id = params[:user_id]
    if user_id.blank?
      render json: { error: "User ID is required" }, status: :bad_request and return
    end

    # Find the user
    user = User.find_by(id: user_id)
    if user.nil?
      render json: { error: "User not found" }, status: :not_found and return
    end

    # Generate OTP code for the user
    user.generate_o

    # Update the user's 2FA status
    if user.update(otp_enabled: true)
      # Notify the user (e.g., send OTP code via email)
      UserMailer.otp_sent(user).deliver_later

      # Create and broadcast a notification to the user
      create_and_broadcast_notification(user, "Two-factor authentication has been enabled for your account.")

      render json: { message: "Two-factor authentication has been enabled for the user." }, status: :ok
    else
      render json: { error: "Failed to enable two-factor authentication for the user." }, status: :unprocessable_entity
    end
  end


  def disable_two_factor_for_user
    user_id = params[:user_id]
    if user_id.blank?
      render json: { error: "User ID is required" }, status: :bad_request and return
    end

    user = User.find_by(id: user_id)
    if user.nil?
      render json: { error: "User not found" }, status: :not_found and return
    end

    user.clear_otp!
    if user.update(otp_enabled: false)
      create_and_broadcast_notification(user, "Two-factor authentication has been disabled for your account.")
      render json: { message: "Two-factor authentication has been disabled for the user." }, status: :ok
    else
      render json: { error: "Failed to disable two-factor authentication for the user." }, status: :unprocessable_entity
    end
  end
  def enable_two_factor
    if current_user.nil?
      render json: { error: "User not authenticated" }, status: :unauthorized and return
    end

    if code_valid?(params[:otp_code])
      current_user.update(otp_enabled: true, otp_code: nil)
      create_and_broadcast_notification(current_user, "Two-factor authentication has been enabled.")

      render json: { message: "Two-factor authentication has been enabled." }, status: :ok
    else
      render json: { error: "Invalid or expired verification code" }, status: :unprocessable_entity
    end
  end

  def disable_two_factor
    if current_user.nil?
      render json: { error: "User not authenticated" }, status: :unauthorized and return
    end
    current_user.clear_otp!
    current_user.update(otp_enabled: false)
    create_and_broadcast_notification(current_user, "Two-factor authentication has been disabled.")

    render json: { message: "Two-factor authentication has been disabled." }, status: :ok
  end

  private
  def create_and_broadcast_notification(user, message)
    notification = Notification.create!(user: user, title: "2FA Status Change", body: message)
    NotificationChannel.broadcast_to("notification_channel.#{user.id}", notification: notification)
  end


  def code_valid?(code)
    return false if current_user.nil?
    return false if current_user.otp_code != code
    return false if current_user.otp_expires_at.nil? || current_user.otp_expires_at < Time.current
    true
  end


  def authorize_admin!
    unless current_user.admin?
      render json: { error: "Unauthorized" }, status: :unauthorized and return
    end
  end

  def generate_jwt_for_user(user)
    # Standard JWT claims as defined in RFC 7519
    exp = 24.hours.from_now.to_i
    iat = Time.now.to_i

    # Custom claims
    jti = SecureRandom.uuid
    # jti = Digest::MD5.hexdigest(jti_raw.join(":").to_s)

    payload = {
      jti: jti,             # Unique identifier for the JWT
      exp: exp,             # Expiration time
      iat: iat,             # Issued at time
      aud: nil,
      scp: "user",
      sub: user.id.to_s,    # Subject (user ID)
      otp_verified: true    # Custom claim indicating OTP verification status
      # Add any additional custom claims here if needed
    }

    # Encode the payload to generate a new JWT
    jwt_token = JWT.encode(payload, Rails.application.credentials.jwt_secret_key)

    # Decode and verify the generated token
    decoded_token = JWT.decode(jwt_token, Rails.application.credentials.jwt_secret_key)

    jwt_token # Return the generated token
  rescue JWT::EncodeError, JWT::DecodeError => e
    Rails.logger.error("Failed to generate or decode token: #{e.message}")
    nil # Return nil in case of errors
  end

  def invalidate_token(authorization_header)
    return unless authorization_header.present?

    token = authorization_header.split(" ").last
    decoded_token = JWT.decode(token, nil, false).first
    JwtDenylist.create!(jti: decoded_token["jti"], exp: Time.at(decoded_token["exp"]))
  rescue JWT::DecodeError => e
    Rails.logger.error("Failed to decode token: #{e.message}")
  end
end
