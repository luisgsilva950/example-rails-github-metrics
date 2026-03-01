class CreateDeliverables < ActiveRecord::Migration[8.1]
  def change
    create_table :deliverables, id: :uuid do |t|
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.references :cycle, null: true, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :jira_link
      t.string :specific_stack, null: false
      t.float :total_effort_hours, null: false, default: 0.0
      t.integer :priority, default: 0
      t.string :status, null: false, default: "backlog"

      t.timestamps
    end

    add_index :deliverables, :specific_stack
    add_index :deliverables, :status
    add_index :deliverables, :priority
  end
end
