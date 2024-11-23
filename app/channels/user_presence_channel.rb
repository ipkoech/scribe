class UserPresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_presence_channel"
    current_user.appear
  end

  def unsubscribed
    current_user.disappear
  end

  def appear(data)
    current_user.appear(on: data["appearing_on"])
  end

  def away
    current_user.away
  end
end
