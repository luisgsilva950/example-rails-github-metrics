class CreateCycles < ActiveRecord::Migration[8.1]
  def change
    create_table :cycles, id: :uuid do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      t.timestamps
    end

    add_index :cycles, :start_date
    add_index :cycles, :end_date
  end
end
