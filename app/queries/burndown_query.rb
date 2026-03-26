# frozen_string_literal: true

class BurndownQuery
  def initialize(holiday_dates: [])
    @holiday_dates = holiday_dates.to_set
  end

  def call(deliverable:, cycle:)
    work_dates = work_dates_for(cycle)
    return { planned: [], executed: [] } if work_dates.empty?

    allocations = deliverable.deliverable_allocations
    planned_hours = compute_daily_hours(allocations, work_dates)
    entries = entries_by_date(deliverable)

    planned = build_series(deliverable.total_effort_hours, work_dates, planned_hours)
    executed = build_executed_series(deliverable.total_effort_hours, work_dates, planned_hours, entries)
    { planned: planned, executed: executed }
  end

  private

  def work_dates_for(cycle)
    (cycle.start_date..cycle.end_date).select do |d|
      !d.saturday? && !d.sunday? && !@holiday_dates.include?(d)
    end
  end

  def compute_daily_hours(allocations, work_dates)
    work_dates.each_with_object({}) do |date, map|
      map[date] = allocated_hours_on(allocations, date)
    end
  end

  def allocated_hours_on(allocations, date)
    count = allocations.count do |a|
      date >= a.start_date && date <= a.end_date
    end
    count * 8
  end

  def entries_by_date(deliverable)
    deliverable.burndown_entries.group_by(&:date).transform_values do |day_entries|
      { total: day_entries.sum(&:hours_burned), count: day_entries.size }
    end
  end

  def build_series(total_effort, work_dates, daily_hours)
    remaining = total_effort.to_f
    work_dates.map do |date|
      remaining -= daily_hours[date]
      { date: date.to_s, remaining: remaining }
    end
  end

  def build_executed_series(total_effort, work_dates, planned_hours, entries)
    remaining = total_effort.to_f
    work_dates.map do |date|
      remaining -= burned_hours(planned_hours[date], entries[date])
      { date: date.to_s, remaining: remaining }
    end
  end

  def burned_hours(planned, entry_data)
    return planned unless entry_data

    unaffected = planned - (entry_data[:count] * 8)
    entry_data[:total] + [ unaffected, 0 ].max
  end
end
