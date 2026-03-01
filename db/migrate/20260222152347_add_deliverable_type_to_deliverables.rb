class AddDeliverableTypeToDeliverables < ActiveRecord::Migration[8.1]
  def change
    add_column :deliverables, :deliverable_type, :string
  end
end
