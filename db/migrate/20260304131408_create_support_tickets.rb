class CreateSupportTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :support_tickets do |t|
      t.string :issue_key, null: false
      t.string :title, null: false
      t.string :status
      t.string :priority
      t.string :team
      t.string :assignee
      t.string :reporter
      t.datetime :opened_at, null: false
      t.datetime :jira_updated_at
      t.string :components, array: true, default: []
      t.text :description

      t.timestamps
    end

    add_index :support_tickets, :issue_key, unique: true
    add_index :support_tickets, :team
    add_index :support_tickets, :status
    add_index :support_tickets, :priority
    add_index :support_tickets, :opened_at
    add_index :support_tickets, :jira_updated_at
  end
end
