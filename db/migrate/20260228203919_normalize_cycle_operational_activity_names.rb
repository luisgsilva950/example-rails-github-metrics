class NormalizeCycleOperationalActivityNames < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE cycle_operational_activities
      SET name = LOWER(name)
      WHERE name IS DISTINCT FROM LOWER(name)
    SQL
  end

  def down
    # Irreversible: original casing is unknown
  end
end
