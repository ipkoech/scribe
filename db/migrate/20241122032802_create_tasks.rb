class CreateTasks < ActiveRecord::Migration[7.2]
  def change
    create_table :tasks, id: :uuid do |t|
      t.string :title
      t.text :description
      t.datetime :due_date
      t.string :status, default: "pending"
      t.datetime :completed_at
      t.string :priority
      t.datetime :start_date
      t.time :time
      t.integer :remind_before
      t.references :assignee, foreign_key: { to_table: :users }, type: :uuid
      t.references :creator, foreign_key: { to_table: :users }, type: :uuid
      t.references :taskable, polymorphic: true, type: :uuid

      t.timestamps
    end
  end
end
