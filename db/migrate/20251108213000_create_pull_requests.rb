class CreatePullRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :pull_requests do |t|
      t.references :repository, null: false, foreign_key: true
      t.bigint :github_id, null: false
      t.integer :number, null: false
      t.string :title
      t.string :state, null: false
      t.string :author_login
      t.string :author_name
      t.string :normalized_author_name
      t.datetime :opened_at
      t.datetime :closed_at
      t.datetime :merged_at
      t.integer :additions
      t.integer :deletions
      t.integer :changed_files

      t.timestamps
    end

    add_index :pull_requests, :github_id, unique: true
    add_index :pull_requests, [ :repository_id, :number ], unique: true
    add_index :pull_requests, :normalized_author_name
    add_index :pull_requests, :state
    add_index :pull_requests, :opened_at
  end
end
