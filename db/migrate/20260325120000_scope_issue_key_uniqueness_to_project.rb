class ScopeIssueKeyUniquenessToProject < ActiveRecord::Migration[8.1]
  def change
    remove_index :sonar_issues, :issue_key, unique: true
    add_index :sonar_issues, [ :sonar_project_id, :issue_key ], unique: true
  end
end
