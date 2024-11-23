class CreateDrafts < ActiveRecord::Migration[7.2]
  def change
    create_table :drafts, id: :uuid do |t|
      t.string :title
      t.text :content
      t.string :content_type
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.boolean :active, default: false
      t.text :original_content
      t.string :status, default: "editing"

      t.timestamps
    end

    create_table :drafts_users, id: false do |t|
      t.belongs_to :draft, type: :uuid, null: false, foreign_key: true
      t.belongs_to :user, type: :uuid, null: false, foreign_key: true
      t.string :reason
      t.string :access_level
    end

    add_index :drafts_users, [:draft_id, :user_id], unique: true
  end
end
