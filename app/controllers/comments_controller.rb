class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_commentable, only: [:create]
  before_action :set_comment, only: [:destroy, :update, :show]

  def show
    authorize @comment, :show?
    render json: @comment, status: :ok
  rescue Pundit::NotAuthorizedError
    render json: { error: "You are not authorized to view this comment." }, status: :forbidden
  end

  def index
    # Apply policy scope to filter comments based on user permissions
    comments = policy_scope(Comment)
    comments = comments.ransack(params[:q]).result

    comments = comments.where(commentable_id: params[:commentable_id]) if params[:commentable_id].present?

    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      comments = comments.order(order_params)
    else
      comments = comments.order(created_at: :asc)
    end

    if params[:per_page].to_i == -1
      comments = comments.all
      render json: {
        data: comments.map { |comment| format_comment(comment) },
        current_page: 1,
        per_page: comments.size,
        total_pages: 1,
        total: comments.size,
        first_page: true,
        last_page: true,
        out_of_range: false,
      }
    else
      comments = comments.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: {
        data: comments.map { |comment| format_comment(comment) },
        current_page: comments.current_page,
        per_page: comments.limit_value,
        total_pages: comments.total_pages,
        total: comments.total_count,
        first_page: comments.first_page?,
        last_page: comments.last_page?,
        out_of_range: comments.out_of_range?,
      }
    end
  end

  def create
    authorize Comment
    @comment = @commentable.comments.new(comment_params)
    @comment.user = current_user

    if @comment.save
      render json: format_comment(@comment), status: :created
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  rescue Pundit::NotAuthorizedError
    render json: { error: "You are not authorized to comment on this item." }, status: :forbidden
  end

  def update
    authorize @comment
    if @comment.update(comment_params)
      render json: format_comment(@comment), status: :ok
    else
      render json: @comment.errors, status: :unprocessable_entity
    end
  rescue Pundit::NotAuthorizedError
    render json: { error: "You are not authorized to update this comment." }, status: :forbidden
  end

  def destroy
    authorize @comment
    @comment.destroy
    head :no_content
  rescue Pundit::NotAuthorizedError
    render json: { error: "You are not authorized to delete this comment." }, status: :forbidden
  end

  private

  def set_commentable
    @commentable = find_commentable
    raise Pundit::NotAuthorizedError unless @commentable
  end

  def find_commentable
    # Dynamically find the commentable object based on the type
    params[:commentable_type].constantize.find(params[:commentable_id])
  rescue NameError, ActiveRecord::RecordNotFound
    nil
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.permit(:content)
  end

  def format_comment(comment)
    {
      id: comment.id,
      content: comment.content,
      commentable_id: comment.commentable_id,
      commentable_type: comment.commentable_type,
      user: comment.user.as_json(only: [:id, :f_name, :email]),
      created_at: comment.created_at,
      updated_at: comment.updated_at,
    }
  end
end
