# frozen_string_literal: true

FactoryBot.define do
  factory :commit do
    repository
    sequence(:sha) { |n| Digest::SHA1.hexdigest("commit-#{n}") }
    author_name { "Jane Doe" }
    message { "Fix bug in feature X" }
    committed_at { 1.day.ago }
  end
end
