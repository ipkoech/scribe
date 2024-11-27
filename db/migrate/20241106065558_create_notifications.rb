class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :recipient, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.references :actor, type: :uuid, foreign_key: { to_table: :users }
      t.references :notifiable, type: :uuid, polymorphic: true
      t.string :action
      t.jsonb :data
      t.datetime :read_at

      t.timestamps
    end

    add_index :notifications, [ :recipient_id, :read_at ]
  end
end
