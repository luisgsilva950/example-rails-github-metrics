class CreateSonarIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :sonar_issues, id: :uuid do |t|
      t.references :sonar_project, null: false, foreign_key: true, type: :uuid
      t.string :issue_key, null: false
      t.string :issue_type, null: false
      t.string :severity
      t.string :status
      t.text :message
      t.string :component
      t.integer :line
      t.string :effort
      t.datetime :creation_date
      t.datetime :update_date
      t.string :tags, array: true, default: []

      t.timestamps
    end

    add_index :sonar_issues, :issue_key, unique: true
    add_index :sonar_issues, %i[sonar_project_id issue_type]
  end
end
