class CreateAbsences < ActiveRecord::Migration[8.1]
  def change
    create_table :absences, id: :uuid do |t|
      t.references :developer, null: false, foreign_key: true, type: :uuid
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :reason

      t.timestamps
    end
  end
end
