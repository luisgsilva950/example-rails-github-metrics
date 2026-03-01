require "test_helper"

class Metrics::AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @repo1 = Repository.create!(name: "org/repo1", github_id: 111, language: "Ruby")
    @repo2 = Repository.create!(name: "org/repo2", github_id: 222, language: "Ruby")
    Commit.create!(repository: @repo1, sha: "a1", message: "msg", author_name: "Alice", normalized_author_name: "alice", committed_at: Time.current)
    Commit.create!(repository: @repo1, sha: "a2", message: "msg", author_name: "Bob", normalized_author_name: "bob", committed_at: Time.current)
    Commit.create!(repository: @repo2, sha: "a3", message: "msg", author_name: "Alice", normalized_author_name: "alice", committed_at: Time.current)
  end

  test "should return ranking ordered by total commits desc with SQL pagination" do
    get "/metrics/authors"
    assert_response :success
    body = JSON.parse(@response.body)
    assert body.key?("content"), "esperado chave content"
    assert body.key?("meta"), "esperado chave meta"
    assert_equal 2, body["content"].size
    assert_equal "alice", body["content"].first["author"]
    assert_equal 2, body["content"].first["total_commits"]
    # Breakdown repos
    repo_names = body["content"].first["repos"].map { |r| r["name"] }.sort
    assert_equal ["org/repo1", "org/repo2"].sort, repo_names
    assert_equal 1, body["meta"]["page"]
    assert_equal 25, body["meta"]["size"]
    assert_equal 2, body["meta"]["total_authors"]
    assert_equal 1, body["meta"]["total_pages"]
  end

  test "pagination with size=1 page=2 returns second author only (SQL)" do
    get "/metrics/authors", params: { size: 1, page: 2 }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 1, body["content"].size
    assert_equal "bob", body["content"].first["author"]
    assert_equal 2, body["meta"]["total_authors"]
    assert_equal 2, body["meta"]["total_pages"]
    assert_equal 2, body["meta"]["page"]
    assert_equal 1, body["meta"]["size"]
  end
end
