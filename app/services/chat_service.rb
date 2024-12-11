class ChatService
  BASE_URL = "http://135.236.101.9:8006/v1"

  def initialize(chat, is_new)
    @chat = chat
    @is_new = is_new
    @user = chat.conversation.user
  end

  def call
    uri = URI(BASE_URL + "/models/chat-transcribe")
    request = Net::HTTP::Post.new(uri)
    request["accept"] = "application/json"

    # Form data
    form_data = [
      ["user_id", @user.id.to_s],
      ["conversation_id", @chat.conversation.id.to_s],
      ["user_input", @chat.user_input],
      ["new_conversation", @is_new.to_s],
    ]

    # If a file is attached to the chat, append it to the form data
    if @chat.file.attached?
      file = @chat.file
      form_data << [
        "file",
        file.download, # Download the file content
        { filename: file.filename.to_s, content_type: file.content_type },
      ]
    end

    # Set form data for the multipart request
    request.set_form(form_data, "multipart/form-data")

    # Make the HTTP request
    response = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end

    JsonParserService.parse(response.body)
  rescue StandardError => e
    Rails.logger.error "API request failed: #{e.message}"
    nil
  end
end
