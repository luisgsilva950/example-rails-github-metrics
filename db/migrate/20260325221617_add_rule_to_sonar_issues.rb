class AddRuleToSonarIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :sonar_issues, :rule, :string
  end
end
