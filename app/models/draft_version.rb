class DraftVersion < ApplicationRecord
  belongs_to :draft
  belongs_to :user
end
