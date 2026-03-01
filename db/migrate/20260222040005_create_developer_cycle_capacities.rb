class CreateDeveloperCycleCapacities < ActiveRecord::Migration[8.1]
  def change
    create_table :developer_cycle_capacities, id: :uuid do |t|
      t.references :cycle, null: false, foreign_key: true, type: :uuid
      t.references :developer, null: false, foreign_key: true, type: :uuid
      t.float :gross_hours, null: false, default: 0.0
      t.float :real_capacity, null: false, default: 0.0

      t.timestamps
    end

    add_index :developer_cycle_capacities, %i[cycle_id developer_id],
              unique: true, name: "idx_dev_cycle_capacities_unique"
  end
end
