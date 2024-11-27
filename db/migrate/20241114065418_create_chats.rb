class CreateChats < ActiveRecord::Migration[7.2]
  def change
    create_table :chats, id: :uuid do |t|
      t.text :user_input
      t.text :bot_reply
      t.string :role
      t.references :conversation, null: false, foreign_key: true, type: :uuid
      t.boolean :liked, default: false
      t.boolean :disliked, default: false
      t.text :highlighted_text
      t.text :reply_to_highlight

      t.timestamps
    end
  end
end
