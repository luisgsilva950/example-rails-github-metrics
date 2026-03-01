# frozen_string_literal: true

FactoryBot.define do
  factory :developer do
    team
    sequence(:name) { |n| "Developer #{n}" }
    domain_stack { "backend" }
    seniority { "mid" }
    productivity_factor { 0.80 }
  end
end
