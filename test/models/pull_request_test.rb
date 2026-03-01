require "test_helper"

class PullRequestTest < ActiveSupport::TestCase
  setup do
    @repo = Repository.create!(name: "org/repo1", github_id: 999, language: "Ruby")
  end

  test "creates and normalizes author name" do
    pr = PullRequest.create!(repository: @repo, github_id: 12345, number: 10, state: "open", author_name: "Alice")
    assert_equal "alice", pr.normalized_author_name
  end

  test "uniqueness constraints" do
    PullRequest.create!(repository: @repo, github_id: 12345, number: 10, state: "open")
    dup = PullRequest.new(repository: @repo, github_id: 12345, number: 10, state: "open")
    assert_not dup.valid?
    assert_includes dup.errors[:github_id], "has already been taken"
  end
end
