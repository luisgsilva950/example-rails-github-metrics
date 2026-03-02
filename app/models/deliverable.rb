class Deliverable < ApplicationRecord
  SPECIFIC_STACKS = %w[backend frontend fullstack mobile data].freeze
  STATUSES = %w[backlog prioritized in_cycle done].freeze
  DELIVERABLE_TYPES = %w[bet spillover technical_debt].freeze

  belongs_to :team
  belongs_to :cycle, optional: true
  has_many :deliverable_allocations, dependent: :destroy
  has_many :burndown_entries, dependent: :destroy
  has_many :developers, through: :deliverable_allocations

  validates :title, presence: true
  validates :specific_stack, presence: true, inclusion: { in: SPECIFIC_STACKS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :total_effort_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :deliverable_type, presence: true, inclusion: { in: DELIVERABLE_TYPES }

  scope :backlog, -> { where(cycle_id: nil) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_stack, ->(stack) { where(specific_stack: stack) }
  scope :ordered, -> { order(priority: :asc, created_at: :desc) }
end
