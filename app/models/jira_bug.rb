class JiraBug < ApplicationRecord
  SAO_PAULO_TZ = "America/Sao_Paulo"
  EXCLUDED_LABELS = %w[jira_escalated Failure delayed].freeze
  CATEGORY_PREFIXES = %w[feature project mfe data_integrity_reason].freeze

  enum :development_type, { Backend: "Backend", Frontend: "Frontend" }, validate: { allow_nil: true }

  validates :issue_key, :title, :opened_at, presence: true
  validates :issue_key, uniqueness: true

  scope :recent, -> { where("opened_at >= ?", 30.days.ago) }
  scope :done, -> { where(status: "10 Done") }
  scope :by_status, ->(s) { where(status: s) }
  scope :by_priority, ->(p) { where(priority: p) }
  scope :by_team, ->(t) { where(team: t) }
  scope :recently_updated, -> { where("jira_updated_at >= ?", 30.days.ago) }

  scope :by_date_range, ->(start_date, end_date, tz: SAO_PAULO_TZ) {
    zone = Time.find_zone(tz)
    rel = all
    rel = rel.where("opened_at >= ?", zone.parse("#{start_date} 00:00:00").utc) if start_date.present?
    rel = rel.where("opened_at <= ?", zone.parse("#{end_date} 23:59:59").utc) if end_date.present?
    rel
  }

  scope :with_category_prefix, ->(prefix) {
    where("EXISTS (SELECT 1 FROM unnest(categories) AS cat WHERE cat LIKE ?)", "#{prefix}:%")
  }

  scope :with_category, ->(category) {
    where("? = ANY(categories)", category)
  }

  def self.distinct_categories(scope = all)
    sql = scope.select("unnest(categories) AS cat").to_sql
    connection.select_values("SELECT DISTINCT cat FROM (#{sql}) AS t ORDER BY cat")
  end

  def self.filter_categories(categories)
    Array(categories).reject { |c| EXCLUDED_LABELS.include?(c) }
  end
end
