# frozen_string_literal: true

FactoryBot.define do
  factory :cycle do
    sequence(:name) { |n| "Sprint #{n}" }
    start_date { Date.current }
    end_date { 14.days.from_now.to_date }
  end
end
