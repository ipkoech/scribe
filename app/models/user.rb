class User < ApplicationRecord
  # Include default devise modules. Others available are:
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable, :lockable, :trackable,
         :jwt_authenticatable, jwt_revocation_strategy: JwtDenylist

  # RBAC associations
  has_and_belongs_to_many :roles
  has_many :roles_permissions, through: :roles, source: :permissions
  has_many :permissions, through: :roles
  has_and_belongs_to_many :shared_conversations, through: :conversations
  has_many :media
  has_many :conversations
  has_many :drafts
  # has_and_belongs_to_many :drafts
  has_one_attached :profile_image

  # Notifications associations
  has_many :received_notifications, class_name: "Notification", as: :recipient
  has_many :sent_notifications, class_name: "Notification", as: :actor

  def mark_all_notifications_as_read!
    notifications.where(read_at: nil).update_all(read_at: Time.current)
  end

  # JWT Methods
  def self.find_by_jwt_token(token)
    payload, header = JWT.decode(token, Rails.application.credentials.jwt_secret_key!)
    expiration_time = Time.at(payload["exp"])
    return nil if JwtDenylist.find_by(jti: payload["jti"], exp: expiration_time)
    User.find(payload["sub"])
  rescue JWT::DecodeError => e
    # Return the error
    e
  end

  def as_json(options = {})
    attrs = attributes.except(
      "encrypted_password",
      "reset_password_token",
      "confirmation_token",
      "unlock_token"
    )

    attrs.merge!(
      roles: roles.map { |role| role.slice(:id, :name) },
      profile_image_url: profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(profile_image, only_path: true) : nil,
    )

    attrs
  end

  def profile_image_url
    profile_image.attached? ? profile_image.url : nil
  end

  # Generates an OTP, stores it along with the expiration time
  def generate_otp!
    User.transaction do
      self.otp_code = 6.times.map { rand(10) }.join
      self.otp_expires_at = 15.minutes.from_now
      save!
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  # Verifies the provided OTP code against the stored one and checks if it's expired
  def verify_otp?(provided_otp)
    otp_code == provided_otp && otp_expires_at > Time.current
  end

  # Clears the stored OTP code and expiration time
  def clear_otp!
    User.transaction do
      update!(otp_code: nil, otp_expires_at: nil)
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  # Implement the otp back_up codes
  def generate_otp_backup_codes # Generate 10 backup codes
    10.times.map { SecureRandom.hex(4) }
  end

  # RBAC methods
  def assign_role(role)
    roles << role unless roles.include?(role)
  end

  def remove_role(role)
    roles.delete(role)
  end

  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def has_permission?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def highest_role_level
    roles.maximum(:hierarchy_level)
  end

  def active_roles
    roles.where(is_active: true)
  end

  def permissions_for_resource(resource_type)
    permissions.where(resource_type: resource_type)
  end

  # Ransackable Attributes
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "updated_at", "f_name", "l_name"]
  end

  def self.ransortable_attributes(auth_object = nil)
    ["created_at", "updated_at", "f_name", "l_name"]
  end

  def appear(on: nil)
    update(online: true, last_seen_at: Time.current, appearing_on: on)
    ActionCable.server.broadcast("user_presence_channel", { user: self, status: "online", appearing_on: on })
  end

  def away
    update(online: false)
    ActionCable.server.broadcast("user_presence_channel", { user: self, status: "away" })
  end

  def disappear
    update(online: false)
    ActionCable.server.broadcast("user_presence_channel", { user: self, status: "offline" })
  end

  private

  def saved
    UserChannel.broadcast_to(self, user: self)
  end

  def updated
    UserChannel.broadcast_to(self, user: self)
  end
end
