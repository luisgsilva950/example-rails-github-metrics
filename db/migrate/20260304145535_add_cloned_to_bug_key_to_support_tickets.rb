class AddClonedToBugKeyToSupportTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :support_tickets, :cloned_to_bug_key, :string
  end
end
