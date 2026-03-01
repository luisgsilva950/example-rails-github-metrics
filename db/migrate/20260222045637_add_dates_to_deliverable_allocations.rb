class AddDatesToDeliverableAllocations < ActiveRecord::Migration[8.1]
  def change
    add_column :deliverable_allocations, :start_date, :date, null: false
    add_column :deliverable_allocations, :end_date, :date, null: false
  end
end
