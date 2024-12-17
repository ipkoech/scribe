class PasswordsController < ApplicationController
def forgot
    if params[:email].blank?
      return render json: { errors: { email: ["can't be blank"] } }, status: :unprocessable_entity
    end
    user = User.find_by(email: params[:email])
    if user.nil?
      return render json: { errors: { email: ["email address not found"] } }, status: :unprocessable_entity
    end
    token = user.send_reset_password_instructions
    Rails.logger.info ("Token : #{token}")
    UserMailer.reset_password_instructions(user, token).deliver_later
    render json: { message: "Reset password instructions sent to #{params[:email]}" }, status: :ok
  end

  def reset
    params.require([:token, :password, :password_confirmation])
    user = User.find_by(reset_password_token: params[:token])
    if user.present? && user.reset_password_period_valid?
      if user.reset_password(params[:password], params[:password_confirmation])
        render json: { message: "Password has been reset successfully." }, status: :ok
      else
        render json: { error: user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      return render json: { errors: { token: ["user info not found"] } }, status: :unprocessable_entity
    end
  end

  def edit
      params.require(:reset_password_token)
      token = params[:reset_password_token]
      # TODO: add env variable for frontend
      redirect_to "http://localhost:4200/reset?token=#{token}" and return
  end
end