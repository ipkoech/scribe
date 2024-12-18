require "diff/lcs"

class DraftsController < ApplicationController
  before_action :set_draft, only: %i[ show update destroy ]

  # GET /drafts
  def index
    drafts = policy_scope(Draft).ransack(params[:q]).result

    # Apply filters
    if params.dig(:filter, :status).present?
      status_filter = params[:filter][:status]
      # Split status filters by comma and handle exclusions
      if status_filter.start_with?("!")
        excluded_statuses = status_filter[1..-1].split(",")
        drafts = drafts.where.not(status: excluded_statuses)
      else
        statuses = status_filter.split(",")
        drafts = drafts.where(status: statuses)
      end
    end

    drafts = drafts.where(created_at: params[:created_at]) if params[:created_at].present?
    drafts = drafts.where(user_id: params[:user_id]) if params[:user_id].present?
    drafts = drafts.where(fileable_type: params[:fileable_type]) if params[:fileable_type].present?

    # Apply ordering
    if params[:order_by].present?
      order_params = params[:order_by].split(",")
      drafts = drafts.order(order_params)
    else
      drafts = drafts.order(created_at: :desc)
    end

    # Handle pagination
    if params[:per_page].to_i == -1
      drafts = drafts.all
      render json: {
               data: drafts.as_json(include: { author: { only: [:id, :f_name, :email] }, collaborators: { only: [:id, :f_name, :email] } }),
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
               data: drafts.as_json(include: { author: { only: [:id, :f_name, :email] }, collaborators: { only: [:id, :f_name, :email] } }),
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

  def shared_drafts
    # Fetch drafts where the current user is a collaborator, including their access levels
    drafts_users = DraftsUser.where(user_id: current_user.id).includes(:draft)

    # Extract draft IDs based on the DraftsUser records where the user is a collaborator
    draft_ids = drafts_users.pluck(:draft_id)

    # Fetch the associated drafts using the filtered draft IDs
    @drafts = Draft.where(id: draft_ids)

    # Apply additional filters (e.g., status, fileable_type) if provided
    @drafts = @drafts.where(status: params[:status].split(",")) if params[:status].present?
    @drafts = @drafts.where(fileable_type: params[:fileable_type]) if params[:fileable_type].present?

    # Apply ordering
    @drafts = if params[:order_by].present?
        @drafts.order(params[:order_by])
      else
        @drafts.order(created_at: :desc)
      end
    # Handle pagination
    @drafts = @drafts.page(params[:page] || 1).per(params[:per_page] || 10)

    # Build the response with drafts and associated draft_users data
    response_data = @drafts.as_json(
      include: {
        author: { only: [:id, :f_name, :email] },
        collaborators: { only: [:id, :f_name, :email] },
      },
    )

    # Add the access_level from draft_users to each draft in the response
    response_data.each do |draft|
      matching_draft_user = drafts_users.find { |du| du.draft_id == draft["id"] }
      draft["access_level"] = matching_draft_user.access_level if matching_draft_user
    end

    # Add the reason
    response_data.each do |draft|
      matching_draft_user = drafts_users.find { |du| du.draft_id == draft["id"] }
      draft["reason"] = matching_draft_user.reason if matching_draft_user
    end

    render json: {
             data: response_data,
             current_page: @drafts.current_page,
             per_page: @drafts.limit_value,
             total_pages: @drafts.total_pages,
             total: @drafts.total_count,
             first_page: @drafts.first_page?,
             last_page: @drafts.last_page?,
             out_of_range: @drafts.out_of_range?,
           }, status: :ok
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
        collaborators: { only: [:id, :f_name, :email, :last_seen_at] },
        comments: {
          include: { user: { only: [:id, :f_name, :email] } },
          only: [:id, :content, :created_at, :updated_at],
        },
        draft_versions: {
          include: { user: { only: [:id, :f_name, :email] } },
          only: [:id, :content, :content_changes, :created_at, :updated_at],
        },
      },
    ), status: :ok
  end

  def update
    @draft = Draft.find(params[:id])
    old_content = @draft.content

    if @draft.update(draft_params)
      create_draft_version(old_content)
      render json: @draft, status: :ok
    else
      render json: { errors: @draft.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def history
    @draft = Draft.find(params[:id])
    versions = @draft.draft_versions.order(created_at: :asc).includes(:user)
    render json: versions, include: { user: { only: [:id, :f_name, :email] } }
  end

  # app/controllers/drafts_controller.rb
  def start_review
    @draft = Draft.find(params[:id])
    authorize @draft

    ActiveRecord::Base.transaction do
      if @draft.update(status: "reviewing")
        review_users = User.joins(roles: :permissions)
                           .where(permissions: { name: "review draft" })
                           .distinct

        frontend_url = "#{Rails.application.credentials.frontend_url}/content/review/#{@draft.id}"

        review_users.each do |user|
          NotificationService.notify(
            user: user,
            body: "You have been assigned to review the draft #{@draft.title}. Please complete it by #{(Time.current + 3.days).strftime("%B %d, %Y")}.",
            extra_params: {
              title: "New Draft Review Task Assigned",
              description: "You have been assigned to review the draft #{@draft.title}. Please complete it by #{(Time.current + 3.days).strftime("%B %d, %Y")}.",
              notifiable_type: "Draft",
              notifiable_id: @draft.id,
              draft_id: @draft.id,
              frontend_url: frontend_url,
              trigger_name: "start_review",
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
        frontend_url = "#{Rails.application.credentials.frontend_url}/content/posts/#{@draft.id}"

        NotificationService.notify(
          user: @draft.author,
          body: "Your draft has been reviewed and approved. Check the generated posts in the posts section.",
          extra_params: {
            title: "'#{@draft.title}' draft has been approved",
            description: "Your draft has been reviewed and approved. Check the generated posts in the posts section.",
            notifiable_type: "Draft",
            notifiable_id: @draft.id,
            draft_id: @draft.id,
            frontend_url: frontend_url,
            trigger_name: "approved",
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
        frontend_url = "#{Rails.application.credentials.frontend_url}/content/drafts/#{@draft.id}"
        reason = params[:reason]

        NotificationService.notify(
          user: @draft.author,
          body: "Your draft has been reviewed and unfortunately, it has been rejected. Please review the feedback and consider making revisions.",
          extra_params: {
            title: "'#{@draft.title}' draft has been rejected",
            description: "Your draft has been reviewed and unfortunately, it has been rejected due to #{reason}. Please review the feedback and consider making revisions.",
            notifiable_type: "Draft",
            notifiable_id: @draft.id,
            draft_id: @draft.id,
            frontend_url: frontend_url,
            trigger_name: "rejected",
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
            frontend_url = "#{Rails.application.credentials.frontend_url}/content/drafts/#{@draft.id}"

            NotificationService.notify(
              user: user,
              body: "You have been given #{access_level} access to the draft for the following reason: #{reason}.",
              extra_params: {
                title: "You have been added as a collaborator to '#{@draft.title}'",
                description: "You have been given #{access_level} access to the draft for the following reason: #{reason}.",
                notifiable_type: "Draft",
                notifiable_id: @draft.id,
                frontend_url: frontend_url,
                trigger_name: "new_collaborator",
              },
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
      frontend_url = "#{Rails.application.credentials.frontend_url}/content/drafts/#{@draft.id}"
      NotificationService.notify(
        user: @draft.author,
        body: "#{added_users.map(&:f_name).join(", ")} has been added as collaborators to your draft for the following reason: #{reason}.",
        extra_params: {
          title: "'#{@draft.title}' collaborator(s) added successfully",
          description: "You have been given #{access_level} access to the draft for the following reason: #{reason}.",
          notifiable_type: "Draft",
          notifiable_id: @draft.id,
          frontend_url: frontend_url,
          actor: current_user,
          trigger_name: "new_collaborator",
        },
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
                description: "Your access to this  '#{@draft.title}' has been revoked.",
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

  def create_draft_version(old_content)
    changes = calculate_changes(old_content, @draft.content)
    @draft.draft_versions.create(
      content: old_content,
      content_changes: changes,
      user: current_user,
    )
  end

  def calculate_changes(old_content, new_content)
    changes = {}
    old_lines = old_content.split("\n")
    new_lines = new_content.split("\n")

    diff = Diff::LCS.diff(old_lines, new_lines)

    diff.each_with_index do |change, index|
      change.each do |c|
        line_number = c.position + 1
        changes[line_number] ||= { removed: [], added: [] }

        case c.action
        when "+"
          changes[line_number][:added] << c.element
        when "-"
          changes[line_number][:removed] << c.element
        end
      end
    end

    changes
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
