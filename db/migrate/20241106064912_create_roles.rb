class CreateRoles < ActiveRecord::Migration[7.2]
  def change
    create_table :roles, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.integer :hierarchy_level, default: 0
      t.boolean :is_active, default: true
      t.string :created_by
      t.string :updated_by

      t.timestamps
    end

    add_index :roles, :name, unique: true
    add_index :roles, :hierarchy_level
    add_index :roles, :is_active

    create_table :roles_users, id: false do |t|
      t.belongs_to :role, type: :uuid, null: false, foreign_key: true
      t.belongs_to :user, type: :uuid, null: false, foreign_key: true
    end

    add_index :roles_users, [ :role_id, :user_id ], unique: true
  end
end
