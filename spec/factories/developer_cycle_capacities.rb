# frozen_string_literal: true

FactoryBot.define do
  factory :developer_cycle_capacity do
    cycle
    developer
    gross_hours { 40.0 }
    real_capacity { 32.0 }
  end
end
