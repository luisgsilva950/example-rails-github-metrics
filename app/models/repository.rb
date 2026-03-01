class Repository < ApplicationRecord
  has_many :commits, dependent: :destroy
  has_many :pull_requests, dependent: :destroy
  validates :name, :github_id, presence: true, uniqueness: true
end
