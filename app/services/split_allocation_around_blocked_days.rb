# frozen_string_literal: true

class SplitAllocationAroundBlockedDays
  def call(allocation:)
    blocked = blocked_dates(allocation)
    return [] if blocked.empty?

    segments = build_segments(allocation.start_date, allocation.end_date, blocked)
    valid = segments.select { |s, e| any_work_day?(s, e, allocation.developer_id) }

    return [] if unchanged?(allocation, valid)

    replace_with_segments(allocation, valid)
  end

  private

  def blocked_dates(allocation)
    holidays = weekday_holidays(allocation.start_date, allocation.end_date)
    absences = weekday_absences(allocation.developer_id, allocation.start_date, allocation.end_date)
    (holidays + absences).uniq.sort
  end

  def weekday_holidays(start_date, end_date)
    Holiday.dates_between(start_date, end_date)
           .reject { |d| d.saturday? || d.sunday? }
  end

  def weekday_absences(developer_id, start_date, end_date)
    Absence.where(developer_id: developer_id)
           .overlapping(start_date, end_date)
           .flat_map { |a| (clamp(a.start_date, start_date)..clamp_end(a.end_date, end_date)).to_a }
           .reject { |d| d.saturday? || d.sunday? }
  end

  def clamp(date, min)
    date < min ? min : date
  end

  def clamp_end(date, max)
    date > max ? max : date
  end

  def build_segments(start_date, end_date, blocked)
    segments = []
    current_start = start_date

    blocked.each do |day|
      segment_end = day - 1.day
      segments << [ current_start, segment_end ] if current_start <= segment_end
      current_start = day + 1.day
    end

    segments << [ current_start, end_date ] if current_start <= end_date
    segments
  end

  def any_work_day?(start_date, end_date, developer_id)
    holidays = Holiday.dates_between(start_date, end_date)
    absences = Absence.where(developer_id: developer_id)
                      .overlapping(start_date, end_date)
                      .flat_map { |a| (clamp(a.start_date, start_date)..clamp_end(a.end_date, end_date)).to_a }
                      .to_set

    (start_date..end_date).any? do |d|
      !d.saturday? && !d.sunday? && !holidays.include?(d) && !absences.include?(d)
    end
  end

  def unchanged?(allocation, valid_segments)
    valid_segments.size == 1 &&
      valid_segments.first == [ allocation.start_date, allocation.end_date ]
  end

  def replace_with_segments(allocation, segments)
    attrs = {
      deliverable_id: allocation.deliverable_id,
      developer_id: allocation.developer_id
    }

    ActiveRecord::Base.transaction do
      allocation.destroy!
      segments.map do |s, e|
        DeliverableAllocation.create_without_auto_split!(
          **attrs, start_date: s, end_date: e,
          allocated_hours: 1, operational_hours: 0
        )
      end
    end
  end
end
