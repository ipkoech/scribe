class FileUploadJob < ApplicationJob
  queue_as :default

  def perform(action, chat_id, data = {})
    chat = Chat.find(chat_id)

    case action
    when "upload_file"
      upload_file(chat, data[:file_data])
    when "broadcast_success"
      broadcast_success(chat)
      # Add more actions here as needed
    else
      Rails.logger.warn "Unknown action: #{action}"
    end
  end

  private

  def upload_file(chat, file_data)
    chat.file.attach(file_data)
    Rails.logger.info "File attached to Chat ID: #{chat.id}"
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Chat not found: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "File attachment failed: #{e.message}"
  end

  def broadcast_success(chat)
    ActionCable.server.broadcast(
      "conversation_channel_#{chat.conversation_id}",
      {
        action: "file_uploaded",
        chat_id: chat.id,
      }
    )
    Rails.logger.info "Broadcasted file upload success for Chat ID: #{chat.id}"
  rescue StandardError => e
    Rails.logger.error "Broadcast failed: #{e.message}"
  end
end
