class Team < ApplicationRecord
  has_many :developers, dependent: :destroy
  has_many :deliverables, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
