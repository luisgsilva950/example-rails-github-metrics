class Cycle < ApplicationRecord
  has_many :deliverables, dependent: :nullify
  has_many :developer_cycle_capacities, dependent: :destroy
  has_many :developers, through: :developer_cycle_capacities
  has_many :cycle_operational_activities, dependent: :destroy

  validates :name, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.current, Date.current) }
  scope :upcoming, -> { where("start_date > ?", Date.current) }

  def gross_hours
    work_days * 8
  end

  def total_weekdays
    (start_date..end_date).count { |d| !d.saturday? && !d.sunday? }
  end

  def work_days
    holidays = Holiday.dates_between(start_date, end_date)
    (start_date..end_date).count { |d| !d.saturday? && !d.sunday? && !holidays.include?(d) }
  end

  def holiday_count
    Holiday.dates_between(start_date, end_date).size
  end

  def operational_activities_for(developer_id)
    cycle_operational_activities
      .for_developer(developer_id)
      .overlapping(start_date, end_date)
  end

  def operational_days_for(developer_id)
    activities = operational_activities_for(developer_id)
    return 0 if activities.empty?

    holidays = Holiday.dates_between(start_date, end_date)
    (start_date..end_date).count do |d|
      next false if d.saturday? || d.sunday? || holidays.include?(d)

      activities.any? { |a| d >= a.start_date && d <= a.end_date }
    end
  end

  def operational_hours_for(developer_id)
    operational_days_for(developer_id) * 8
  end

  def unallocated_operational_days_for(developer_id)
    activities = operational_activities_for(developer_id)
    return 0 if activities.empty?

    alloc_ranges = allocation_ranges_for(developer_id)
    absence_ranges = absence_ranges_for(developer_id)
    holidays = Holiday.dates_between(start_date, end_date)

    (start_date..end_date).count do |d|
      next false if d.saturday? || d.sunday? || holidays.include?(d)
      next false if covered_by?(d, alloc_ranges)
      next false if covered_by?(d, absence_ranges)

      activities.any? { |a| d >= a.start_date && d <= a.end_date }
    end
  end

  def unallocated_operational_hours_for(developer_id)
    unallocated_operational_days_for(developer_id) * 8
  end

  private

  def allocation_ranges_for(developer_id)
    DeliverableAllocation.joins(:deliverable)
      .where(developer_id: developer_id, deliverables: { cycle_id: id })
      .pluck(:start_date, :end_date)
  end

  def absence_ranges_for(developer_id)
    Absence.where(developer_id: developer_id)
           .overlapping(start_date, end_date)
           .pluck(:start_date, :end_date)
  end

  def covered_by?(date, ranges)
    ranges.any? { |s, e| date >= s && date <= e }
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end
end
