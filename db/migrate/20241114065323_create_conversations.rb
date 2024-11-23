class CreateConversations < ActiveRecord::Migration[7.2]
  def change
    create_table :conversations, id: :uuid do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.boolean :archived, default: false

      t.timestamps
    end
    create_table :conversations_users, id: false do |t|
      t.belongs_to :conversation, type: :uuid, null: false, foreign_key: true
      t.belongs_to :user, type: :uuid, null: false, foreign_key: true
    end

    add_index :conversations_users, [ :conversation_id, :user_id ], unique: true
  end
end
