class CreateBurndownEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :burndown_entries, id: :uuid do |t|
      t.references :deliverable, null: false, foreign_key: true, type: :uuid
      t.date :date, null: false
      t.float :hours_burned, null: false, default: 0.0
      t.string :note
      t.timestamps
    end

    add_index :burndown_entries, %i[deliverable_id date], unique: true
  end
end
