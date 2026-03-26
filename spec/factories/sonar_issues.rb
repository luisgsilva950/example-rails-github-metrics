FactoryBot.define do
  factory :sonar_issue do
    sonar_project
    sequence(:issue_key) { |n| "AXyz#{n}" }
    issue_type { "BUG" }
    severity { "MAJOR" }
    status { "OPEN" }
    rule { "java:S1234" }
    message { "Fix this bug" }
    component { "src/main.rb" }
    line { 42 }
    effort { "15min" }
    creation_date { 1.week.ago }
    update_date { 1.day.ago }
    tags { [] }

    trait :vulnerability do
      issue_type { "VULNERABILITY" }
      severity { "CRITICAL" }
      message { "Fix this vulnerability" }
    end

    trait :code_smell do
      issue_type { "CODE_SMELL" }
      severity { "MINOR" }
      message { "Refactor this code" }
    end

    trait :security_hotspot do
      issue_type { "SECURITY_HOTSPOT" }
      severity { "MAJOR" }
      message { "Review this security hotspot" }
    end

    trait :closed do
      status { "CLOSED" }
    end

    trait :resolved do
      status { "RESOLVED" }
    end
  end
end
