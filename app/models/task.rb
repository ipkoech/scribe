class Task < ApplicationRecord
  belongs_to :assignee
  belongs_to :creator
  belongs_to :taskable, polymorphic: true
end
