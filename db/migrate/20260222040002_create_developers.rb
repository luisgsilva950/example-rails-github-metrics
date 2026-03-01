class CreateDevelopers < ActiveRecord::Migration[8.1]
  def change
    create_table :developers, id: :uuid do |t|
      t.references :team, null: false, foreign_key: true, type: :uuid
      t.string :name, null: false
      t.string :domain_stack, null: false
      t.string :seniority, null: false
      t.decimal :productivity_factor, precision: 4, scale: 2, null: false, default: 1.0

      t.timestamps
    end

    add_index :developers, :domain_stack
    add_index :developers, :seniority
  end
end
