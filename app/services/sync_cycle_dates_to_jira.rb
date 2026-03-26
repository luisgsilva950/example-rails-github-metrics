# frozen_string_literal: true

class SyncCycleDatesToJira
  def initialize(sync_service: SyncDatesToJira.new)
    @sync_service = sync_service
  end

  def call(cycle:)
    deliverables = cycle.deliverables.where.not(jira_link: [ nil, "" ])
    return { results: [], total: 0 } if deliverables.empty?

    results = deliverables.map { |d| sync_one(d) }
    { results: results, total: results.size }
  end

  private

  def sync_one(deliverable)
    result = @sync_service.call(deliverable: deliverable)
    { deliverable_id: deliverable.id, title: deliverable.title, **result }
  rescue StandardError => e
    { deliverable_id: deliverable.id, title: deliverable.title, success: false, error: e.message }
  end
end
