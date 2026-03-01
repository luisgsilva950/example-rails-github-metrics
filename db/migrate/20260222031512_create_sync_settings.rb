class CreateSyncSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :sync_settings do |t|
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :sync_settings, :key, unique: true
  end
end
