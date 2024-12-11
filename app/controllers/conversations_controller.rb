class ConversationsController < ApplicationController
  before_action :set_conversation, only: [:show, :archive, :share, :destroy, :update, :unarchive]

  # GET /conversations
  def index
    conversations = policy_scope(Conversation).ransack(params[:q]).result

    # Apply filters
    if params.dig(:filter, :archived).present?
      archived_filter = params[:filter][:archived]
      conversations = conversations.where(archived: archived_filter == "true")
    else
      conversations = conversations.where(archived: false)
    end

    conversations = conversations.where(created_at: params[:created_at]) if params[:created_at].present?
    conversations = conversations.where(user_id: params[:user_id]) if params[:user_id].present?

    # Apply ordering
    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      conversations = conversations.order(order_params)
    else
      conversations = conversations.order(updated_at: :desc)
    end

    # Handle pagination
    if params[:per_page].to_i == -1
      conversations = conversations.all
      render json: {
        data: conversations.as_json(include: { user: { only: [:id, :f_name, :email] }, shared_users: { only: [:id, :f_name, :email] } }),
        current_page: 1,
        per_page: conversations.size,
        total_pages: 1,
        total: conversations.size,
        first_page: true,
        last_page: true,
        out_of_range: false,
      }, status: :ok
    else
      conversations = conversations.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: {
        data: conversations.as_json(include: { user: { only: [:id, :f_name, :email] }, shared_users: { only: [:id, :f_name, :email] } }),
        current_page: conversations.current_page,
        per_page: conversations.limit_value,
        total_pages: conversations.total_pages,
        total: conversations.total_count,
        first_page: conversations.first_page?,
        last_page: conversations.last_page?,
        out_of_range: conversations.out_of_range?,
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

  # POST /conversations/:id/unarchive
  def unarchive
    if @conversation.update(archived: false)
      render json: { message: "Conversation unarchived successfully" }, status: :ok
    else
      render json: { errors: @conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /conversations/:id/share
  def share
    user = User.find_by(email: params[:email])

    # generate a link for sharing the conversation, this link should expire after 24 hours'
    # link = conversation_url(host: Rails.application.config.action_mailer.default_url_options[:host], id: @conversation.id)
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
