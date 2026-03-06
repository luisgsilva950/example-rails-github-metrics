# frozen_string_literal: true

class SupportTicket < ApplicationRecord
  SAO_PAULO_TZ = "America/Sao_Paulo"

  validates :issue_key, :title, :opened_at, presence: true
  validates :issue_key, uniqueness: true

  scope :by_team, ->(team) { where(team: team) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :recent, -> { where("opened_at >= ?", 30.days.ago) }
  scope :most_recent, -> { order(opened_at: :desc) }
  scope :not_cloned, -> { where(cloned_to_bug_key: nil) }

  scope :by_date_range, ->(start_date, end_date, tz: SAO_PAULO_TZ) {
    zone = Time.find_zone(tz)
    rel = all
    rel = rel.where("opened_at >= ?", zone.parse("#{start_date} 00:00:00").utc) if start_date.present?
    rel = rel.where("opened_at <= ?", zone.parse("#{end_date} 23:59:59").utc) if end_date.present?
    rel
  }
end
