# frozen_string_literal: true

FactoryBot.define do
  factory :deliverable_allocation do
    deliverable
    developer
    start_date { Date.current }
    end_date { 4.days.from_now.to_date }
    allocated_hours { 8.0 }
    skip_auto_split { true }
  end
end
