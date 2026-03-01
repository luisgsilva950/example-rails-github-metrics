class PullRequest < ApplicationRecord
  belongs_to :repository

  validates :github_id, :number, :state, presence: true
  validates :github_id, uniqueness: true
  validates :number, uniqueness: { scope: :repository_id }

  before_create :normalize_author_name

  scope :merged, -> { where.not(merged_at: nil) }
  scope :open_state, -> { where(state: 'open') }

  private

  def normalize_author_name
    return if author_name.blank?
    self.normalized_author_name = AuthorNameNormalizer.new.call(author_name)
  end
end
