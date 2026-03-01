class CreateJiraBugs < ActiveRecord::Migration[8.1]
  def change
    create_table :jira_bugs do |t|
      t.string :issue_key, null: false
      t.string :title, null: false
      t.datetime :opened_at, null: false
      t.string :components, array: true, default: []
      t.string :categories, array: true, default: []
      t.text :root_cause_analysis

      t.timestamps
    end

    add_index :jira_bugs, :issue_key, unique: true
    add_index :jira_bugs, :opened_at
  end
end
