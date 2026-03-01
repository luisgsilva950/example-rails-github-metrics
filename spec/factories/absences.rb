# frozen_string_literal: true

FactoryBot.define do
  factory :absence do
    developer
    start_date { Date.current }
    end_date { Date.current + 2.days }
    reason { "Vacation" }
  end
end
