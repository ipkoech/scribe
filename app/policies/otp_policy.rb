class OtpPolicy < ApplicationPolicy
    attr_reader :user, :record
  
    def initialize(user, record)
      @user = user
      @record = record
    end
  
    # Policy for sending OTP
    def send_otp?
      user.present?  # Any authenticated user can request OTP (for their own account)
    end
  
    # Policy for verifying OTP
    def verify?
      user.present?  # Any authenticated user can verify their OTP
    end
  
    # Admin-only policies
    def enable_two_factor_for_user?
      user_is_admin?  # Only admins can enable 2FA for other users
    end
  
    def disable_two_factor_for_user?
      user_is_admin?  # Only admins can disable 2FA for other users
    end
  
    # Policies for managing user's own 2FA status
    def enable_two_factor?
      user.present?  # A user can enable 2FA on their own account
    end
  
    def disable_two_factor?
      user.present?  # A user can disable 2FA on their own account
    end
  
    private
  
    # Check if the user is an admin
    def user_is_admin?
        user.roles.exists?(name: "Admin") || user.roles.exists?(name: "Super Admin")
    end
  end
  