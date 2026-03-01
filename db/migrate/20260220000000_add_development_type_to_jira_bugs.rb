class AddDevelopmentTypeToJiraBugs < ActiveRecord::Migration[8.0]
  def change
    add_column :jira_bugs, :development_type, :string
  end
end
