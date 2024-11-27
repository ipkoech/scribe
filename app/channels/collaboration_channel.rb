class CollaborationChannel < ApplicationCable::Channel
  def subscribed
    draft = Draft.find(params[:draft_id])
    stream_for draft
  end

  def unsubscribed
    draft = Draft.find(params[:draft_id])
    # Optional: Notify other collaborators that a user has left
    CollaborationChannel.broadcast_to(draft, { user_id: current_user.id, action: "left_draft" })
  end

  def receive(data)
    draft = Draft.find(params[:draft_id])
    CollaborationChannel.broadcast_to(draft, data)
  end

  def start_typing(data)
    draft = Draft.find(params[:draft_id])
    CollaborationChannel.broadcast_to(draft, {
      user_id: data["user_id"],
      action: "start_typing",
    })
  end

  def stop_typing(data)
    draft = Draft.find(params[:draft_id])
    CollaborationChannel.broadcast_to(draft, {
      user_id: data["user_id"],
      action: "stop_typing",
    })
  end

  def update_cursor_position(data)
    draft = Draft.find(params[:draft_id])
    CollaborationChannel.broadcast_to(draft, {
      user_id: data["user_id"],
      position: data["position"],
      action: "cursor_position",
    })
  end
end
