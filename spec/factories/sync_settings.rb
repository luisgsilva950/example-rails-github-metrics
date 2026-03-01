# frozen_string_literal: true

FactoryBot.define do
  factory :sync_setting do
    key { "jira_bugs" }
    enabled { false }
    last_synced_at { nil }
    status { "idle" }

    trait :enabled do
      enabled { true }
    end

    trait :with_last_sync do
      last_synced_at { 10.minutes.ago }
    end

    trait :failed do
      status { "failed" }
      last_error { "Connection refused" }
    end
  end
end
