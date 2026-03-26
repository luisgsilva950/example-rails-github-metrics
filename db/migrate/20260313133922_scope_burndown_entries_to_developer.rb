class ScopeBurndownEntriesToDeveloper < ActiveRecord::Migration[8.1]
  def up
    remove_index :burndown_entries, name: "idx_burndown_entries_deliverable_date"
    backfill_developer_on_deliverable_entries
    remove_orphaned_entries
    add_index :burndown_entries, %i[deliverable_id developer_id date], unique: true,
              where: "deliverable_id IS NOT NULL AND developer_id IS NOT NULL",
              name: "idx_burndown_entries_deliverable_developer_date"
  end

  def down
    remove_index :burndown_entries, name: "idx_burndown_entries_deliverable_developer_date"
    add_index :burndown_entries, %i[deliverable_id date], unique: true,
              where: "deliverable_id IS NOT NULL", name: "idx_burndown_entries_deliverable_date"
  end

  private

  def backfill_developer_on_deliverable_entries
    execute <<~SQL.squish
      UPDATE burndown_entries be
      SET developer_id = da.developer_id
      FROM deliverable_allocations da
      WHERE be.deliverable_id IS NOT NULL
        AND be.developer_id IS NULL
        AND da.deliverable_id = be.deliverable_id
        AND be.date BETWEEN da.start_date AND da.end_date
    SQL

    insert_extra_developer_entries
  end

  def insert_extra_developer_entries
    execute <<~SQL.squish
      INSERT INTO burndown_entries (id, deliverable_id, developer_id, date, hours_burned, note, created_at, updated_at)
      SELECT gen_random_uuid(), be.deliverable_id, da.developer_id, be.date, be.hours_burned, be.note, be.created_at, be.updated_at
      FROM burndown_entries be
      JOIN deliverable_allocations da
        ON da.deliverable_id = be.deliverable_id
        AND be.date BETWEEN da.start_date AND da.end_date
      WHERE be.deliverable_id IS NOT NULL
        AND be.developer_id IS NOT NULL
        AND da.developer_id != be.developer_id
        AND NOT EXISTS (
          SELECT 1 FROM burndown_entries existing
          WHERE existing.deliverable_id = be.deliverable_id
            AND existing.developer_id = da.developer_id
            AND existing.date = be.date
        )
    SQL
  end

  def remove_orphaned_entries
    execute <<~SQL.squish
      DELETE FROM burndown_entries
      WHERE deliverable_id IS NOT NULL AND developer_id IS NULL
    SQL
  end
end
