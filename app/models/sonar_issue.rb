class SonarIssue < ApplicationRecord
  belongs_to :sonar_project

  validates :issue_key, presence: true, uniqueness: { scope: :sonar_project_id }
  validates :issue_type, presence: true

  scope :bugs, -> { where(issue_type: "BUG") }
  scope :vulnerabilities, -> { where(issue_type: "VULNERABILITY") }
  scope :code_smells, -> { where(issue_type: "CODE_SMELL") }
  scope :security_hotspots, -> { where(issue_type: "SECURITY_HOTSPOT") }
  scope :by_severity, ->(severity) { where(severity: severity) }
  scope :by_status, ->(status) { where(status: status) }
  scope :open, -> { where(status: %w[OPEN CONFIRMED REOPENED]) }
  scope :resolved, -> { where(status: %w[CLOSED RESOLVED FIXED WONTFIX]) }
  scope :critical_or_blocker, -> { where(severity: %w[CRITICAL BLOCKER]) }
  scope :critical_counts_by_project, -> { open.critical_or_blocker.group(:sonar_project_id, :issue_type).count }
  scope :pick_descriptions, -> { minimum(:message) }
end
