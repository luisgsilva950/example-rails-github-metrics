# frozen_string_literal: true

FactoryBot.define do
  factory :burndown_entry do
    deliverable
    date { Date.current }
    hours_burned { 4.0 }
    note { nil }
  end
end
