# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Metrics::Authors", type: :request do
  describe "GET /metrics/authors" do
    it "returns a paginated list of authors ranked by commits" do
      repo = create(:repository)
      create(:commit, repository: repo, author_name: "Jane Doe")
      create(:commit, repository: repo, author_name: "Jane Doe")
      create(:commit, repository: repo, author_name: "John Smith")

      get "/metrics/authors", params: { page: 1, size: 10 }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["content"]).to be_an(Array)
      expect(body["meta"]["page"]).to eq(1)
      expect(body["meta"]["size"]).to eq(10)
      expect(body["meta"]["total_authors"]).to eq(2)
    end

    it "returns repo breakdown for each author" do
      repo = create(:repository, name: "org/my-repo")
      create(:commit, repository: repo, author_name: "Jane Doe")

      get "/metrics/authors", params: { page: 1, size: 10 }

      body = response.parsed_body
      author_entry = body["content"].find { |a| a["author"] == "jane doe" }
      expect(author_entry["repos"]).to be_an(Array)
      expect(author_entry["total_repos"]).to be >= 1
    end

    it "handles empty results" do
      get "/metrics/authors", params: { page: 1, size: 10 }

      body = response.parsed_body
      expect(body["content"]).to eq([])
      expect(body["meta"]["total_authors"]).to eq(0)
    end

    it "defaults to page 1 and size 25" do
      get "/metrics/authors"

      body = response.parsed_body
      expect(body["meta"]["page"]).to eq(1)
      expect(body["meta"]["size"]).to eq(25)
    end

    it "handles invalid page and size" do
      get "/metrics/authors", params: { page: -1, size: 0 }

      body = response.parsed_body
      expect(body["meta"]["page"]).to eq(1)
      expect(body["meta"]["size"]).to eq(25)
    end

    it "caps size at 10000" do
      get "/metrics/authors", params: { size: 99999 }

      body = response.parsed_body
      expect(body["meta"]["size"]).to eq(10000)
    end

    it "paginates correctly" do
      repo = create(:repository)
      3.times { |i| create(:commit, repository: repo, author_name: "Author #{i}") }

      get "/metrics/authors", params: { page: 2, size: 1 }

      body = response.parsed_body
      expect(body["content"].size).to eq(1)
      expect(body["meta"]["total_pages"]).to eq(3)
    end
  end
end
