class AddExtendedFieldsToJiraBugs < ActiveRecord::Migration[8.1]
  def change
    change_table :jira_bugs do |t|
      t.string :priority
      t.string :team
      t.string :issue_type
      t.string :reporter
      t.string :status
      t.string :assignee
      t.text :description
      t.datetime :jira_updated_at
      t.string :labels, array: true, default: []
      t.jsonb :development_info
      t.integer :comments_count
      t.jsonb :comments
    end

    add_index :jira_bugs, :priority
    add_index :jira_bugs, :team
    add_index :jira_bugs, :status
    add_index :jira_bugs, :issue_type
    add_index :jira_bugs, :jira_updated_at
  end
end
