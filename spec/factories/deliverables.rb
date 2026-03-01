# frozen_string_literal: true

FactoryBot.define do
  factory :deliverable do
    team
    cycle { nil }
    sequence(:title) { |n| "Deliverable #{n}" }
    specific_stack { "backend" }
    total_effort_hours { 16.0 }
    priority { 0 }
    status { "backlog" }
    deliverable_type { "bet" }
  end
end
