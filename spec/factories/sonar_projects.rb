FactoryBot.define do
  factory :sonar_project do
    sequence(:sonar_key) { |n| "org_repo-#{n}" }
    sequence(:name) { |n| "repo-#{n}" }
    qualifier { "TRK" }
    visibility { "private" }
    last_analysis_date { 1.day.ago }
    bugs { 0 }
    vulnerabilities { 0 }
    code_smells { 0 }
    security_hotspots { 0 }
    ncloc { 1000 }
    coverage { 80.0 }
    duplicated_lines_density { 3.0 }
    reliability_rating { "A" }
    security_rating { "A" }
    sqale_rating { "A" }

    trait :with_issues do
      bugs { 5 }
      vulnerabilities { 2 }
      code_smells { 10 }
      security_hotspots { 1 }
    end

    trait :low_coverage do
      coverage { 20.0 }
    end
  end
end
