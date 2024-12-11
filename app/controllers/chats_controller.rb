class ChatsController < ApplicationController
  before_action :set_chat, only: [:highlight, :like, :dislike, :update]
  before_action :set_conversation, only: [:create, :index]

  # POST /conversations/:conversation_id/chats
  def create
    user_input = params[:user_input]
    file = params[:file]

    # Check if the conversation is new
    is_new_conversation = @conversation.chats.empty?

    # Create a chat for the user input
    @user_chat = @conversation.chats.create!(user_input: user_input, role: "user")

    if file.present?
      FileUploadJob.perform_now("upload_file", @user_chat.id, file_data: file)
      FileUploadJob.perform_later("broadcast_success", @user_chat.id)
    end

    ActionCable.server.broadcast("conversation_channel_#{@conversation.id}", {
      action: "chat_created",
      chat: @user_chat.as_json,
    })

    # Generate bot response using ChatService
    chat_service = ChatService.new(@user_chat, is_new_conversation)
    bot_response = chat_service.call

    if bot_response
      # Rails.logger.info "Bot response: #{bot_response["content"]}"
      # Update the same chat instance with bot response
      @user_chat.update(bot_reply: bot_response["content"], role: "bot")

      # Add 'new' tag if it's a new conversation
      if is_new_conversation && @conversation.title.blank?
        @conversation.update(title: bot_response["title"])
        # Broadcast new conversation title to other users
        ActionCable.server.broadcast("conversation_channel_#{@conversation.id}", {
          action: "new_conversation_title",
          title: @conversation.title,
        })
      end

      render json: { status: :ok }
    else
      @user_chat.destroy
      render json: { error: "Failed to process your request" }, status: :unprocessable_entity
    end
  end

  # GET /conversations/:conversation_id/chats
  def index
    # Retrieve the chats for a specific conversation, allowing filters
    chats = @conversation.chats.ransack(params[:q]).result

    # Apply ordering if specified in the request params
    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      chats = chats.order(order_params)
    else
      chats = chats.order(created_at: :asc)  # Default to ascending order by creation time
    end

    # Apply pagination
    if params[:per_page].to_i == -1
      chats = chats.all
      render json: {
               data: chats.as_json,
               current_page: 1,
               per_page: chats.size,
               total_pages: 1,
               total: chats.size,
               first_page: true,
               last_page: true,
               out_of_range: false,
             }, status: :ok
    else
      chats = chats.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: {
               data: chats.as_json,
               current_page: chats.current_page,
               per_page: chats.limit_value,
               total_pages: chats.total_pages,
               total: chats.total_count,
               first_page: chats.first_page?,
               last_page: chats.last_page?,
               out_of_range: chats.out_of_range?,
             }, status: :ok
    end
  end

  # PATCH /chats/:id/highlight
  def highlight
    if @chat.update(highlight_params)
      render json: @chat, status: :ok
    else
      render json: { errors: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /chats/:id/like
  def like
    if @chat.liked?
      @chat.update(liked: nil)
    else
      @chat.like!
    end

    render json: @chat, status: :ok
  end

  def update
    if @chat.update(chat_params)
      render json: @chat.as_json, status: :ok
    else
      render json: { errors: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /chats/:id/dislike
  def dislike
    if @chat.disliked?
      @chat.update(disliked: nil)
    else
      @chat.dislike!
    end

    render json: @chat, status: :ok
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
    render json: { error: "Chat not found" }, status: :not_found unless @chat
  end

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
    render json: { error: "Conversation not found" }, status: :not_found unless @conversation
  end

  def chat_params
    params.require(:chat).permit(:user_input, :bot_reply, :file)
  end

  def highlight_params
    params.require(:chat).permit(:highlighted_text, :reply_to_highlight)
  end
end
