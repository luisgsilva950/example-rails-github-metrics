# frozen_string_literal: true

FactoryBot.define do
  factory :support_ticket do
    sequence(:issue_key) { |n| "SUP-#{1000 + n}" }
    title { "Support ticket #{issue_key}" }
    opened_at { 1.week.ago }
    status { "Open" }
    team { "Digital Farm" }
    priority { "Medium" }
    assignee { "John Doe" }
    reporter { "Jane Smith" }
    components { [] }

    trait :high_priority do
      priority { "High" }
    end

    trait :closed do
      status { "Closed" }
    end

    trait :with_components do
      components { %w[Billing Payments] }
    end
  end
end
