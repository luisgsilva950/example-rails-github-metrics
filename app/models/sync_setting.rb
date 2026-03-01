# frozen_string_literal: true

class SyncSetting < ApplicationRecord
  STATUSES = %w[idle syncing completed failed].freeze

  validates :key, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  def self.for(key)
    find_or_create_by!(key: key.to_s)
  end

  def self.enabled?(key)
    find_by(key: key.to_s)&.enabled? || false
  end

  def mark_syncing!
    update!(status: "syncing", last_error: nil)
  end

  def mark_completed!
    update!(status: "completed", last_synced_at: Time.current, last_error: nil)
  end

  def mark_failed!(error_message)
    update!(status: "failed", last_error: error_message.to_s.truncate(500))
  end

  def syncing?
    status == "syncing"
  end

  def failed?
    status == "failed"
  end
end
