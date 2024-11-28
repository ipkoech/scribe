class DraftsController < ApplicationController
  before_action :set_draft, only: %i[ show update destroy ]

  # GET /drafts
  # list all drafts
  def index
    drafts = policy_scope(Draft).ransack(params[:q]).result
    # Apply filters
    if params.dig(:filter, :status).present?
      status_filter = params[:filter][:status]
      if status_filter.start_with?("!")
        drafts = drafts.where.not(status: status_filter[1..-1]) # Exclude completed drafts
      else
        drafts = drafts.where(status: status_filter)
      end
    end
    # drafts = drafts.where(status: params[:status]) if params[:status].present?
    drafts = drafts.where(created_at: params[:created_at]) if params[:created_at].present?
    drafts = drafts.where(user_id: params[:user_id]) if params[:user_id].present?
    drafts = drafts.where(fileable_type: params[:fileable_type]) if params[:fileable_type].present?

    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      drafts = drafts.order(order_params)
    else
      drafts = drafts.order(created_at: :desc)
    end

    if params[:per_page].to_i == -1
      drafts = drafts.all
      render json: {
               data: drafts.as_json(include: {author: { only: [:id, :f_name, :email] }, collaborators: { only: [:id, :f_name, :email] }}),
               current_page: 1,
               per_page: drafts.size,
               total_pages: 1,
               total: drafts.size,
               first_page: true,
               last_page: true,
               out_of_range: false,
             }, status: :ok
    else
      drafts = drafts.page(params[:page] || 1).per(params[:per_page] || 10)
      render json: {
               data: drafts.as_json(include: {author: { only: [:id, :f_name, :email] }, collaborators: { only: [:id, :f_name, :email] }}),
               current_page: drafts.current_page,
               per_page: drafts.limit_value,
               total_pages: drafts.total_pages,
               total: drafts.total_count,
               first_page: drafts.first_page?,
               last_page: drafts.last_page?,
               out_of_range: drafts.out_of_range?,
             }, status: :ok
    end
  end

  # POST /drafts
  def create
    @draft = current_user.drafts.build(draft_params)

    if @draft.save
      render json: @draft, status: :created
    else
      render json: @draft.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @draft = Draft.find(params[:id])
    authorize @draft, :destroy?
    if @draft.destroy
      render json: { message: "Draft deleted successfully" }, status: :ok
    else
      render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    authorize @draft, :show?
    @draft = Draft.find(params[:id])
    render json: @draft.as_json(
      include: {
        author: { only: [:id, :f_name, :email] },
        collaborators: { only: [:id, :f_name, :email] },
        comments: {
          include: { user: { only: [:id, :f_name, :email] } },
          only: [:id, :content, :created_at, :updated_at],
        },
      },
    ), status: :ok
  end

  def update
    @draft = Draft.find(params[:id])
    if @draft.update(draft_params)
      render json: @draft, status: :ok
    else
      render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def start_review
    @draft = Draft.find(params[:id])
    authorize @draft
  
    ActiveRecord::Base.transaction do
      if @draft.update(status: "reviewing")
        review_users = User.joins(roles: :permissions)
          .where(permissions: { name: "review draft" })
          .distinct
  
        frontend_url = "#{Rails.application.credentials.frontend_url}/drafts/#{@draft.id}"
  
        review_users.each do |user|
          NotificationService.notify(
            user: user,
            body: "You have been assigned to review the draft #{@draft.title}. Please complete it by #{(Time.current + 3.days).strftime("%B %d, %Y")}.",
            extra_params: {
              title: "New Draft Review Task Assigned",
              notifiable_type: "Draft",
              notifiable_id: @draft.id,
              draft_id: @draft.id,
              frontend_url: frontend_url,
            },
          )
        end
  
        render json: { draft: @draft }, status: :ok
      else
        render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  rescue NotificationService::NotificationError => e
    render json: { error: e.message }, status: :internal_server_error
  end
  
  def approve
    @draft = Draft.find(params[:id])
    authorize @draft
  
    ActiveRecord::Base.transaction do
      if @draft.update!(status: "approved")
        frontend_url = "#{Rails.application.credentials.frontend_url}/drafts/#{@draft.id}"
  
        NotificationService.notify(
          user: @draft.author,
          body: "Your draft has been reviewed and approved. Check the generated posts in the posts section.",
          extra_params: {
            title: "'#{@draft.title}' draft has been approved",
            notifiable_type: "Draft",
            notifiable_id: @draft.id,
            draft_id: @draft.id,
            frontend_url: frontend_url,
          },
        )
  
        render json: @draft, status: :ok
      else
        raise ActiveRecord::Rollback
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
  rescue NotificationService::NotificationError => e
    render json: { error: e.message }, status: :internal_server_error
  end
  

  def reject
    @draft = Draft.find(params[:id])
    authorize @draft
  
    ActiveRecord::Base.transaction do
      if @draft.update(status: "rejected")
        @draft.tasks.update_all(status: "completed")
        frontend_url = "#{Rails.application.credentials.frontend_url}/drafts/#{@draft.id}"
  
        NotificationService.notify(
          user: @draft.author,
          body: "Your draft has been reviewed and unfortunately, it has been rejected. Please review the feedback and consider making revisions.",
          extra_params: {
            title: "'#{@draft.title}' draft has been rejected",
            notifiable_type: "Draft",
            notifiable_id: @draft.id,
            draft_id: @draft.id,
            frontend_url: frontend_url,
          },
        )
  
        render json: @draft, status: :ok
      else
        render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
        raise ActiveRecord::Rollback
      end
    end
  rescue NotificationService::NotificationError => e
    render json: { error: e.message }, status: :internal_server_error
  end
  

  def add_collaborator
    user_ids = params[:user_ids] || []
    reason = params[:reason] || "Collaborator added"
    access_level = params[:access_level] || "editor"
    added_users = []
    errors = []
    @draft = Draft.find_by(id: params[:id])
  
    ActiveRecord::Base.transaction do
      user_ids.each do |user_id|
        begin
          user = User.find(user_id)
  
          if user == @draft.author
            errors << { user_id: user_id, message: "Cannot add the author as a collaborator." }
            next
          end
  
          if @draft.collaborators.include?(user)
            errors << { user_id: user_id, message: "User is already a collaborator." }
            next
          end
  
          drafts_user = DraftsUser.new(
            draft: @draft,
            user: user,
            reason: reason,
            access_level: access_level,
          )
  
          if drafts_user.save
            frontend_url = "#{Rails.application.credentials.frontend_url}/drafts/#{@draft.id}"
  
            NotificationService.notify(
              user: user,
              body: "You have been given #{access_level} access to the draft for the following reason: #{reason}.",
              extra_params: {
                title: "You have been added as a collaborator to '#{@draft.title}'",
                notifiable_type: "Draft",
                notifiable_id: @draft.id,
                frontend_url: frontend_url,
                trigger_name: "new_collaborator",
              }
            )
  
            added_users << user
          else
            errors << { user_id: user_id, message: drafts_user.errors.full_messages.join(", ") }
            raise ActiveRecord::Rollback
          end
        rescue ActiveRecord::RecordNotFound
          errors << { user_id: user_id, message: "User not found." }
          raise ActiveRecord::Rollback
        rescue => e
          errors << { user_id: user_id, message: "An unexpected error occurred: #{e.message}" }
          raise ActiveRecord::Rollback
        end
      end
  
      if errors.any?
        raise ActiveRecord::Rollback
      end
    end
  
    if added_users.any?
      frontend_url = "#{Rails.application.credentials.frontend_url}/drafts/#{@draft.id}"
      NotificationService.notify(
        user: @draft.author,
        body: "#{added_users.map(&:f_name).join(", ")} has been added as collaborators to your draft for the following reason: #{reason}.",
        extra_params: {
          title: "'#{@draft.title}' collaborator(s) added successfully",
          notifiable_type: "Draft",
          notifiable_id: @draft.id,
          frontend_url: frontend_url,
          actor: current_user
        }
      )
  
      render json: { draft: @draft, added_collaborators: added_users, errors: errors }, status: :ok
    else
      render json: { error: "Unable to add collaborators.", details: errors }, status: :unprocessable_entity
    end
  rescue NotificationService::NotificationError => e
    render json: { error: e.message }, status: :internal_server_error
  end
  

  def remove_collaborator
    user_ids = params[:user_ids] || []
    removed_users = []
    @draft = Draft.find(params[:id])
  
    ActiveRecord::Base.transaction do
      user_ids.each do |user_id|
        begin
          user = User.find(user_id)
          if @draft.collaborators.delete(user)
            removed_users << user
            NotificationService.notify(
              user: user,
              body: "Your access to this draft has been revoked.",
              extra_params: {
                title: "You have been removed from the '#{@draft.title}' draft",
                notifiable_type: "Draft",
                notifiable_id: @draft.id,
                draft_id: @draft.id,
              },
            )
          end
        rescue ActiveRecord::RecordNotFound
          # Optionally, log or collect errors here
          next
        rescue => e
          # Optionally, log or collect errors here
          next
        end
      end
    end
  
    if removed_users.any?
      render json: { draft: @draft, removed_collaborators: removed_users }, status: :ok
    else
      render json: { error: "Unable to remove collaborators." }, status: :unprocessable_entity
    end
  rescue NotificationService::NotificationError => e
    render json: { error: e.message }, status: :internal_server_error
  end
  

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_draft
    @draft = Draft.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def draft_params
    params.require(:draft).permit(
      :title,
      :content,
      :content_type,
      :original_content,
      :status,
      :active
    )
  end
end
