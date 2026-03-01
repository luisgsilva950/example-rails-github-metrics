class DeliverableAllocation < ApplicationRecord
  belongs_to :deliverable
  belongs_to :developer

  attribute :skip_auto_split, :boolean, default: false

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :allocated_hours, presence: true, numericality: { greater_than: 0 }
  validates :operational_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :end_date_after_start_date
  validate :no_overlapping_allocations

  before_validation :compute_hours
  after_create_commit :auto_split, unless: :skip_auto_split

  def self.create_without_auto_split!(**attrs)
    create!(**attrs, skip_auto_split: true)
  end

  def work_days
    return 0 if start_date.blank? || end_date.blank?

    holidays = Holiday.dates_between(start_date, end_date)
    (start_date..end_date).count { |d| !d.saturday? && !d.sunday? && !holidays.include?(d) }
  end

  def operational_days
    return 0 if start_date.blank? || end_date.blank? || deliverable&.cycle.blank?

    activities = deliverable.cycle
                            .operational_activities_for(developer_id)
    return 0 if activities.empty?

    holidays = Holiday.dates_between(start_date, end_date)
    (start_date..end_date).count do |d|
      next false if d.saturday? || d.sunday? || holidays.include?(d)

      activities.any? { |a| d >= a.start_date && d <= a.end_date }
    end
  end

  def plannable_days
    work_days - operational_days
  end

  private

  def auto_split
    SplitAllocationAroundBlockedDays.new.call(allocation: self)
  end

  def compute_hours
    self.operational_hours = operational_days * 8
    self.allocated_hours = plannable_days * 8
  end

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def no_overlapping_allocations
    return if developer_id.blank? || start_date.blank? || end_date.blank? || deliverable.blank?

    overlapping = DeliverableAllocation
      .where(developer_id: developer_id)
      .where.not(id: id)
      .joins(:deliverable)
      .where(deliverables: { cycle_id: deliverable.cycle_id })
      .where("start_date <= ? AND end_date >= ?", end_date, start_date)

    return unless overlapping.exists?

    titles = overlapping.map { |a| a.deliverable.title }.join(", ")
    errors.add(:base, "Developer already allocated during this period (#{titles})")
  end
end
