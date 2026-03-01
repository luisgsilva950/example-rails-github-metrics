# frozen_string_literal: true

FactoryBot.define do
  factory :pull_request do
    repository
    sequence(:github_id) { |n| 200_000 + n }
    sequence(:number) { |n| n }
    state { "closed" }
    title { "Improve performance" }
    author_name { "Jane Doe" }
    author_login { "janedoe" }
    opened_at { 2.days.ago }
    merged_at { 1.day.ago }
    additions { 50 }
    deletions { 10 }
    changed_files { 3 }
  end
end
