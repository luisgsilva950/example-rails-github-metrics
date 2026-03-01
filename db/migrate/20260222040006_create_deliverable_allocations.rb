class CreateDeliverableAllocations < ActiveRecord::Migration[8.1]
  def change
    create_table :deliverable_allocations, id: :uuid do |t|
      t.references :deliverable, null: false, foreign_key: true, type: :uuid
      t.references :developer, null: false, foreign_key: true, type: :uuid
      t.float :allocated_hours, null: false, default: 0.0

      t.timestamps
    end

    add_index :deliverable_allocations, %i[deliverable_id developer_id],
              unique: true, name: "idx_deliverable_allocations_unique"
  end
end
