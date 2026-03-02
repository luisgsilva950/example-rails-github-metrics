# frozen_string_literal: true

class BuildBurndownData
  def initialize(query: BurndownQuery.new)
    @query = query
  end

  def call(deliverable:, cycle:)
    result = @query.call(deliverable: deliverable, cycle: cycle)
    planned = result[:planned]
    ideal = build_ideal_line(deliverable.total_effort_hours, planned)
    { ideal: ideal, planned: planned, executed: result[:executed] }
  end

  private

  def build_ideal_line(total_effort, planned)
    return [] if planned.empty?

    count = planned.size
    daily_burn = total_effort.to_f / count

    planned.each_with_index.map do |point, index|
      remaining = total_effort - (daily_burn * (index + 1))
      { date: point[:date], remaining: remaining.round(1) }
    end
  end
end
