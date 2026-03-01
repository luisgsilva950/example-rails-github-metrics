class RedesignCycleOperationalActivities < ActiveRecord::Migration[8.1]
  def up
    # Clear existing day-of-week records — incompatible with new schema
    execute "DELETE FROM cycle_operational_activities"

    remove_index :cycle_operational_activities,
                 name: "idx_cycle_operational_activities_unique"

    remove_column :cycle_operational_activities, :day_of_week

    add_column :cycle_operational_activities, :developer_id, :uuid, null: true
    add_column :cycle_operational_activities, :start_date, :date, null: false
    add_column :cycle_operational_activities, :end_date, :date, null: false

    add_index :cycle_operational_activities, :developer_id
    add_foreign_key :cycle_operational_activities, :developers, column: :developer_id
  end

  def down
    remove_foreign_key :cycle_operational_activities, :developers
    remove_index :cycle_operational_activities, :developer_id

    remove_column :cycle_operational_activities, :end_date
    remove_column :cycle_operational_activities, :start_date
    remove_column :cycle_operational_activities, :developer_id

    add_column :cycle_operational_activities, :day_of_week, :integer, null: false, default: 1
    add_index :cycle_operational_activities, %i[cycle_id day_of_week],
              unique: true, name: "idx_cycle_operational_activities_unique"
  end
end
