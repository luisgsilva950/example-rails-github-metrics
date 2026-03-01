class CreateCommits < ActiveRecord::Migration[8.1]
  def change
    create_table :commits do |t|
      t.references :repository, null: false, foreign_key: true
      t.string :sha
      t.text :message
      t.string :author_name
      t.datetime :committed_at

      t.timestamps
    end
    add_index :commits, :sha, unique: true
  end
end
