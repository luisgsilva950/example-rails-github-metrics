class CycleOperationalActivity < ApplicationRecord
  ACTIVITY_TYPES = %w[bugs refinement study].freeze
  ACTIVITY_COLORS = {
    "bugs" => "#ef4444",
    "refinement" => "#8b5cf6",
    "study" => "#3b82f6"
  }.freeze

  belongs_to :cycle
  belongs_to :developer, optional: true

  enum :name, ACTIVITY_TYPES.index_by(&:itself), validate: true

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true

  before_validation :assign_color
  validate :end_date_not_before_start_date

  scope :ordered, -> { order(:start_date) }
  scope :for_developer, ->(developer_id) {
    where(developer_id: [ developer_id, nil ])
  }
  scope :overlapping, ->(start_date, end_date) {
    where("start_date <= ? AND end_date >= ?", end_date, start_date)
  }

  def work_days
    return 0 if start_date.blank? || end_date.blank?

    holidays = Holiday.dates_between(start_date, end_date)
    (start_date..end_date).count { |d| weekday?(d) && !holidays.include?(d) }
  end

  def team_wide?
    developer_id.nil?
  end

  private

  def weekday?(date)
    !date.saturday? && !date.sunday?
  end

  def end_date_not_before_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end

  def assign_color
    self.color = ACTIVITY_COLORS[name] || "#6b7280"
  end
end
