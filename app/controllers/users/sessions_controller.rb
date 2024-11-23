class Users::SessionsController < Devise::SessionsController
  respond_to :json

  wrap_parameters :user, include: [ :email, :password ]

    def create
      super do |user|
        if user && user.otp_enabled
          # Send 2FA code here
          user.generate_otp!
          UserMailer.otp_sent(user).deliver_later
        end
      end
    end

  # DELETE /resource/sign_out
  def logout
    # JWT token is sent in the Authorization header
    auth_header = request.headers["Authorization"]
    if auth_header.present? && auth_header.starts_with?("Bearer ")
      token = auth_header.split(" ").last
      begin
        decoded_token = JWT.decode(token, nil, false).first
        JwtDenylist.create!(jti: decoded_token["jti"], exp: Time.at(decoded_token["exp"]))

        # Sign out the user
        sign_out(current_user)

        render json: { message: "Logged out successfully" }, status: :ok
      rescue JWT::DecodeError => e
        render json: { error: "Invalid token: #{e.message}" }, status: :unauthorized
      end
    else
      render json: { error: "Authorization header is missing or malformed" }, status: :unauthorized
    end
  end


  private

  def sign_in_params
    params.require(:user).permit(:email, :password)
  end
end
