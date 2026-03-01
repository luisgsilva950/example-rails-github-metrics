class ConstrainDevelopmentTypeOnJiraBugs < ActiveRecord::Migration[8.1]
  def up
    # Nullify any existing values that are not Backend or Frontend
    execute <<~SQL
      UPDATE jira_bugs
      SET development_type = NULL
      WHERE development_type IS NOT NULL
        AND development_type NOT IN ('Backend', 'Frontend')
    SQL

    add_check_constraint :jira_bugs,
      "development_type IS NULL OR development_type IN ('Backend', 'Frontend')",
      name: "chk_jira_bugs_development_type"
  end

  def down
    remove_check_constraint :jira_bugs, name: "chk_jira_bugs_development_type"
  end
end
