# frozen_string_literal: true

FactoryBot.define do
  factory :holiday do
    sequence(:date) { |n| Date.new(2026, 1, 1) + n.days }
    name { "Test Holiday" }
    scope { "national" }
  end
end
