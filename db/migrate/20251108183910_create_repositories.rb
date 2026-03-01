class CreateRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :repositories do |t|
      t.string :name
      t.bigint :github_id
      t.string :language

      t.timestamps
    end
    add_index :repositories, :name, unique: true
    add_index :repositories, :github_id, unique: true
  end
end
