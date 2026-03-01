class AddBugHoursToDeliverableAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :deliverable_allocations, :bug_hours, :float, default: 0.0, null: false
  end
end
