class CreateSonarProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :sonar_projects, id: :uuid do |t|
      t.string :sonar_key, null: false
      t.string :name, null: false
      t.string :qualifier
      t.string :visibility
      t.datetime :last_analysis_date

      # Cached metric columns
      t.integer :bugs, default: 0, null: false
      t.integer :vulnerabilities, default: 0, null: false
      t.integer :code_smells, default: 0, null: false
      t.integer :security_hotspots, default: 0, null: false
      t.integer :ncloc, default: 0, null: false
      t.float :coverage, default: 0.0, null: false
      t.float :duplicated_lines_density, default: 0.0, null: false

      # Rating columns (A/B/C/D/E)
      t.string :reliability_rating
      t.string :security_rating
      t.string :sqale_rating

      t.datetime :metrics_synced_at
      t.timestamps
    end

    add_index :sonar_projects, :sonar_key, unique: true
  end
end
