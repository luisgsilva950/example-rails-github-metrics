class AddIssuesSyncedAtToSonarProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :sonar_projects, :issues_synced_at, :datetime
  end
end
