class CreateCycleOperationalActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :cycle_operational_activities, id: :uuid do |t|
      t.references :cycle, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.integer :day_of_week, null: false
      t.string :color, null: false, default: "#ef4444"
      t.timestamps
    end

    add_index :cycle_operational_activities, %i[cycle_id day_of_week], unique: true,
              name: "idx_cycle_operational_activities_unique"
  end
end
