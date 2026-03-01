# frozen_string_literal: true

FactoryBot.define do
  factory :repository do
    sequence(:name) { |n| "org/repo-#{n}" }
    sequence(:github_id) { |n| 100_000 + n }
    language { "Ruby" }
  end
end
