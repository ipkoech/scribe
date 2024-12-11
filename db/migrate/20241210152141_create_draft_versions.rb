class CreateDraftVersions < ActiveRecord::Migration[7.2]
  def change
    create_table :draft_versions, id: :uuid do |t|
      t.references :draft, null: false, foreign_key: true, type: :uuid
      t.text :content
      t.text :content_changes
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
