class ConversationsController < ApplicationController
    before_action :set_conversation, only: [ :show, :archive, :share, :destroy, :update ]

    # GET /conversations
    def index
      # Get the active conversations for the current user
      conversations = current_user.conversations.active.ransack(params[:q]).result

      # Apply ordering if specified in the request params
      if params[:order_by].present?
        order_params = params[:order_by].split(",")
        conversations = conversations.order(order_params)
      else
        conversations = conversations.order(updated_at: :desc)  # Order by most recent update by default
      end

      # Apply pagination
      if params[:per_page].to_i == -1
        conversations = conversations.all
        render json: {
          data: conversations.as_json,
          current_page: 1,
          per_page: conversations.size,
          total_pages: 1,
          total: conversations.size,
          first_page: true,
          last_page: true,
          out_of_range: false
        }, status: :ok
      else
        conversations = conversations.page(params[:page] || 1).per(params[:per_page] || 10)
        render json: {
          data: conversations.as_json,
          current_page: conversations.current_page,
          per_page: conversations.limit_value,
          total_pages: conversations.total_pages,
          total: conversations.total_count,
          first_page: conversations.first_page?,
          last_page: conversations.last_page?,
          out_of_range: conversations.out_of_range?
        }, status: :ok
      end
    end


    # POST /conversations
    def create
      @conversation = current_user.conversations.new(conversation_params || {})

      if @conversation.save
        render json: @conversation, status: :created
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /conversations/:id
    def show
      render json: @conversation.to_json(include: :chats), status: :ok
    end

    def update
      if @conversation.update(conversation_params)
        render json: @conversation.as_json, status: :ok
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end
    # PATCH /conversations/:id/archive
    def archive
      if @conversation.update(archived: true)
        render json: { message: "Conversation archived successfully" }, status: :ok
      else
        render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /conversations/:id/share
    def share
      user = User.find_by(email: params[:email])

      if user && @conversation.shared_users << user
        render json: { message: "Conversation shared successfully" }, status: :ok
      else
        render json: { errors: "Unable to share conversation" }, status: :unprocessable_entity
      end
    end

    # DELETE /conversations/:id
    def destroy
      if @conversation.destroy
        render json: { message: "Conversation deleted successfully" }, status: :ok
      else
        render json: { errors: "Unable to delete conversation" }, status: :unprocessable_entity
      end
    end

    private

    def set_conversation
      @conversation = current_user.conversations.find_by(id: params[:id])
      render json: { error: "Conversation not found" }, status: :not_found unless @conversation
    end

    def conversation_params
      params.fetch(:conversation, {}).permit(:title)
    end
end
