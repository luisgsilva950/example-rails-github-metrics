# frozen_string_literal: true

class BurndownEntry < ApplicationRecord
  belongs_to :deliverable, optional: true
  belongs_to :developer, optional: true
  belongs_to :cycle, optional: true

  validates :date, presence: true
  validates :hours_burned, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :date, uniqueness: { scope: :deliverable_id }, if: -> { deliverable_id.present? }
  validates :date, uniqueness: { scope: %i[developer_id cycle_id] }, if: -> { developer_id.present? && cycle_id.present? }
  validate :must_have_deliverable_or_developer

  private

  def must_have_deliverable_or_developer
    return if deliverable_id.present? || deliverable.present?
    return if developer_id.present? || developer.present?

    errors.add(:base, "must belong to a deliverable or a developer")
  end
end
