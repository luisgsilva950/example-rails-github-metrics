# frozen_string_literal: true

FactoryBot.define do
  factory :cycle_operational_activity do
    cycle
    name { "bugs" }
    start_date { Date.new(2026, 2, 25) }
    end_date { Date.new(2026, 2, 25) }
    developer { nil }
  end
end
