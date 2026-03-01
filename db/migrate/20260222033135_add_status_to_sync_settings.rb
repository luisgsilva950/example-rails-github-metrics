class AddStatusToSyncSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :sync_settings, :status, :string, default: "idle", null: false
    add_column :sync_settings, :last_error, :text
  end
end
