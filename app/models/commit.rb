class Commit < ApplicationRecord
  belongs_to :repository
  validates :sha, presence: true, uniqueness: true

  before_create :normalize_author_name

  private

  def normalize_author_name
    return if author_name.blank?
    self.normalized_author_name = AuthorNameNormalizer.new.call(author_name)
  end
end
