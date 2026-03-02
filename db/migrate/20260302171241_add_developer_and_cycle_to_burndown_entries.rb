class AddDeveloperAndCycleToBurndownEntries < ActiveRecord::Migration[8.1]
  def change
    change_column_null :burndown_entries, :deliverable_id, true
    add_reference :burndown_entries, :developer, type: :uuid, foreign_key: true, null: true
    add_reference :burndown_entries, :cycle, type: :uuid, foreign_key: true, null: true

    remove_index :burndown_entries, %i[deliverable_id date], unique: true
    add_index :burndown_entries, %i[deliverable_id date], unique: true,
              where: "deliverable_id IS NOT NULL", name: "idx_burndown_entries_deliverable_date"
    add_index :burndown_entries, %i[developer_id cycle_id date], unique: true,
              where: "developer_id IS NOT NULL AND cycle_id IS NOT NULL",
              name: "idx_burndown_entries_developer_cycle_date"
  end
end
