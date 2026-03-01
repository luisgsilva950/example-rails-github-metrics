# frozen_string_literal: true

class Holiday < ApplicationRecord
  SCOPES = %w[national municipal].freeze

  validates :date, presence: true, uniqueness: true
  validates :name, presence: true
  validates :scope, presence: true, inclusion: { in: SCOPES }

  scope :between, ->(start_date, end_date) { where(date: start_date..end_date) }

  def self.dates_between(start_date, end_date)
    between(start_date, end_date).pluck(:date).to_set
  end
end
