# frozen_string_literal: true

FactoryBot.define do
  factory :jira_bug do
    sequence(:issue_key) { |n| "CWS-#{1000 + n}" }
    title { "Bug #{issue_key}" }
    opened_at { 1.week.ago }
    status { "10 Done" }
    team { "Digital Farm" }
    categories { [] }
    components { [] }
    labels { [] }

    trait :with_feature do
      categories { [ "feature:login", "project:auth" ] }
    end

    trait :with_categories do
      categories { [ "feature:login", "project:auth", "mfe:cw_elements_login" ] }
    end

    trait :data_integrity do
      categories { [ "data_integrity_reason:duplicate_records" ] }
    end

    trait :missing_project do
      categories { [ "feature:login" ] }
    end

    trait :cw_elements_without_mfe do
      categories { [ "feature:login", "project:cw_elements" ] }
    end

    trait :open do
      status { "01 Open" }
    end
  end
end
