module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      reject_unauthorized_connection unless self.current_user
    end

    private

    def find_verified_user
      if user = User.find_by_jwt_token(token)
        user
      else
        reject_unauthorized_connection
      end
    end

    def token
      # Extracting the token from the query parameters
      request.params[:token]
    end
  end
end
