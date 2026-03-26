class SonarProject < ApplicationRecord
  RATING_LABELS = { "1.0" => "A", "2.0" => "B", "3.0" => "C", "4.0" => "D", "5.0" => "E" }.freeze

  has_many :sonar_issues, dependent: :destroy

  validates :sonar_key, presence: true, uniqueness: true
  validates :name, presence: true

  scope :by_name, -> { order(:name) }
  scope :ordered_by_bugs, -> { order(bugs: :desc) }
  scope :ordered_by_coverage, -> { order(coverage: :asc) }
  scope :ordered_by_total_issues, -> { order(Arel.sql("bugs + vulnerabilities + code_smells + security_hotspots DESC, name ASC")) }
  scope :with_critical_issues, -> { where(id: SonarIssue.open.critical_or_blocker.select(:sonar_project_id).distinct) }
  scope :ranked_by_critical_count, lambda {
    joins(:sonar_issues)
      .merge(SonarIssue.open.critical_or_blocker)
      .group("sonar_projects.id")
      .order("COUNT(sonar_issues.id) DESC, sonar_projects.name ASC")
  }
end
