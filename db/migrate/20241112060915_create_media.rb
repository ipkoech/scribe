class CreateMedia < ActiveRecord::Migration[7.2]
  def change
    create_table :media, id: :uuid do |t|
      t.string :title
      t.string :azure_url
      t.string :content_type
      t.float :size
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
