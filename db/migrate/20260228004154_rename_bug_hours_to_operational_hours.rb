class RenameBugHoursToOperationalHours < ActiveRecord::Migration[8.1]
  def change
    rename_column :deliverable_allocations, :bug_hours, :operational_hours
  end
end
