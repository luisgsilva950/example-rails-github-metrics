class Absence < ApplicationRecord
  belongs_to :developer

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :overlapping, ->(start_d, end_d) {
    where("start_date <= ? AND end_date >= ?", end_d, start_d)
  }

  def work_days
    return 0 if start_date.blank? || end_date.blank?

    (start_date..end_date).count { |d| !d.saturday? && !d.sunday? }
  end

  def hours
    work_days * 8
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?

    errors.add(:end_date, "must be on or after start date") if end_date < start_date
  end
end
