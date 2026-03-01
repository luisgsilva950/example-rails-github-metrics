# frozen_string_literal: true

require "rails_helper"

RSpec.describe PullRequest do
  describe "validations" do
    it "requires github_id" do
      pr = build(:pull_request, github_id: nil)

      expect(pr).not_to be_valid
      expect(pr.errors[:github_id]).to include("can't be blank")
    end

    it "requires number" do
      pr = build(:pull_request, number: nil)

      expect(pr).not_to be_valid
      expect(pr.errors[:number]).to include("can't be blank")
    end

    it "requires state" do
      pr = build(:pull_request, state: nil)

      expect(pr).not_to be_valid
      expect(pr.errors[:state]).to include("can't be blank")
    end

    it "requires unique github_id" do
      create(:pull_request, github_id: 999)
      dup = build(:pull_request, github_id: 999)

      expect(dup).not_to be_valid
    end

    it "requires unique number per repository" do
      repo = create(:repository)
      create(:pull_request, repository: repo, number: 42)
      dup = build(:pull_request, repository: repo, number: 42)

      expect(dup).not_to be_valid
    end

    it "allows same number in different repositories" do
      repo1 = create(:repository)
      repo2 = create(:repository)
      create(:pull_request, repository: repo1, number: 42)
      pr = build(:pull_request, repository: repo2, number: 42)

      expect(pr).to be_valid
    end
  end

  describe "scopes" do
    it ".merged returns pull requests with merged_at" do
      repo = create(:repository)
      create(:pull_request, repository: repo, merged_at: 1.day.ago)
      create(:pull_request, repository: repo, merged_at: nil)

      expect(PullRequest.merged.count).to eq(1)
    end

    it ".open_state returns open pull requests" do
      repo = create(:repository)
      create(:pull_request, repository: repo, state: "open")
      create(:pull_request, repository: repo, state: "closed")

      expect(PullRequest.open_state.count).to eq(1)
    end
  end

  describe "before_create :normalize_author_name" do
    it "normalizes author_name on creation" do
      repo = create(:repository)
      pr = create(:pull_request, repository: repo, author_name: "Jane Doe")

      expect(pr.normalized_author_name).to eq("jane doe")
    end

    it "skips normalization when author_name is blank" do
      repo = create(:repository)
      pr = create(:pull_request, repository: repo, author_name: nil)

      expect(pr.normalized_author_name).to be_nil
    end
  end
end
