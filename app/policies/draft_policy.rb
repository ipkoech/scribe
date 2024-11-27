class DraftPolicy < ApplicationPolicy
  attr_reader :user, :draft

  def initialize(user, draft)
    @user = user
    @draft = draft
  end

  def index_comment?
    user_is_owner? || user_is_collaborator?
  end

  def create_comment?
    user_is_owner? || user_is_collaborator?
  end

  def update_comment?
    user_is_owner? || user_is_collaborator?
  end

  def show_comment?
    user_is_owner? || user_is_collaborator?
  end

  def destroy_comment?
    user_is_owner? || user_is_collaborator?
  end

  def create?
    user.has_permission?("create draft")
  end

  def index?
    user.has_permission?("list drafts") || user_is_owner?
  end

  def show?
    user.has_permission?("read draft") || user_is_owner? || user_is_collaborator?
  end

  def update?
    user.has_permission?("update draft") || user_is_owner? || user_is_collaborator
  end

  def destroy?
    user.has_permission?("delete draft") || user_is_owner?
  end

  def approve?
    user.has_permission?("approve draft")
  end

  def reject?
    user.has_permission?("reject draft")
  end

  def start_review?
    user.has_permission?("review draft") || user_is_owner?
  end

  def approve?
    user.has_permission?("approve draft")
  end

  def reject?
    user.has_permission?("reject draft")
  end

  def generate_white_post?
    user_is_owner?
  end

  def generate_social_media_content?
    user_is_owner?
  end

  def generate_blog_content?
    user_is_owner?
  end

  private

  def user_is_owner?
    draft.author == user
  end

  def user_is_collaborator?
    draft.collaborators.include?(user)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Get drafts where the user is either the owner or a collaborator
      user_drafts = scope
        .left_outer_joins(:collaborators)
        .where("drafts.user_id = :user_id OR drafts_users.user_id = :user_id", user_id: user.id)

      # Perform the distinct operation, excluding the JSON fields
      distinct_drafts = user_drafts.select("drafts.id, drafts.title, drafts.user_id, drafts.created_at, drafts.updated_at")

      # Return the complete drafts with the filtered IDs
      scope.where(id: distinct_drafts.map(&:id))
    end
  end
end
