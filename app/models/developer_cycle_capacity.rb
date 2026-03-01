class DeveloperCycleCapacity < ApplicationRecord
  belongs_to :cycle
  belongs_to :developer

  validates :gross_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :real_capacity, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :developer_id, uniqueness: { scope: :cycle_id }
end
