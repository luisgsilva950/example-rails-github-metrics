class RemoveUniqueIndexFromDeliverableAllocations < ActiveRecord::Migration[8.1]
  def change
    remove_index :deliverable_allocations, name: "idx_deliverable_allocations_unique"
    add_index :deliverable_allocations, [ :deliverable_id, :developer_id ], name: "idx_deliverable_allocations_dev_deliverable"
  end
end
