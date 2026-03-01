class Developer < ApplicationRecord
  DOMAIN_STACKS = %w[backend frontend fullstack mobile data].freeze
  SENIORITIES = %w[junior mid senior staff].freeze

  belongs_to :team
  has_many :developer_cycle_capacities, dependent: :destroy
  has_many :cycles, through: :developer_cycle_capacities
  has_many :deliverable_allocations, dependent: :destroy
  has_many :deliverables, through: :deliverable_allocations
  has_many :absences, dependent: :destroy

  validates :name, presence: true
  validates :domain_stack, presence: true, inclusion: { in: DOMAIN_STACKS }
  validates :seniority, presence: true, inclusion: { in: SENIORITIES }
  validates :productivity_factor, presence: true,
            numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  scope :by_stack, ->(stack) { where(domain_stack: stack) }
  scope :by_seniority, ->(level) { where(seniority: level) }
end
