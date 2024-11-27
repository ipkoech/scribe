class CreatePermissions < ActiveRecord::Migration[7.2]
  def change
    create_table :permissions, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.references :access_level, null: false, foreign_key: true, type: :uuid
      t.string :scope
      t.string :resource_type
      t.string :action
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :permissions, :name, unique: true
    add_index :permissions, :scope
    add_index :permissions, :resource_type
    add_index :permissions, :action
    add_index :permissions, :is_active


    create_table :permissions_roles, id: false do |t|
      t.belongs_to :role, type: :uuid, null: false, foreign_key: true
      t.belongs_to :permission, type: :uuid, null: false, foreign_key: true
    end

    add_index :permissions_roles, [ :role_id, :permission_id ], unique: true
  end
end
