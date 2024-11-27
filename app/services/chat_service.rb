class ChatService
  BASE_URL = "http://135.236.101.9:8006/v1"

  def initialize(chat)
    @chat = chat
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

    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "API request failed: #{e.message}"
    nil
  end

  private

  def handle_response(response)
    case response.code.to_i
    when 200
      parse_json_or_text_response(response.body)
    when 422
      handle_unprocessable_entity(response.body)
    else
      Rails.logger.error "Unexpected response: #{response.code} - #{response.body}"
      nil
    end
  end

  def parse_json_or_text_response(body)
    # Attempt to parse the JSON response
    begin
      parsed_response = JSON.parse(body)
      # Ensure the response is a valid JSON object (Hash)
      if parsed_response.is_a?(Hash)
        parsed_response
      else
        body # If it's not a hash, return the raw text
      end
    rescue JSON::ParserError
      body # Return the plain text if it's not valid JSON
    end
  end

  def handle_unprocessable_entity(body)
    error_detail = JSON.parse(body) rescue nil
    if error_detail && error_detail["detail"]
      Rails.logger.error "Validation error: #{error_detail["detail"]}"
    else
      Rails.logger.error "Validation error: Unexpected response format. Response body: #{body}"
    end
    nil
  end
end
