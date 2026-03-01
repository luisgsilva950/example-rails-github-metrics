# frozen_string_literal: true

class FixCycleAllocations
  def initialize(splitter: SplitAllocationAroundBlockedDays.new)
    @splitter = splitter
  end

  def call(cycle:)
    allocations = DeliverableAllocation
      .joins(:deliverable)
      .where(deliverables: { cycle_id: cycle.id })

    allocations.each { |alloc| @splitter.call(allocation: alloc) }
  end
end
