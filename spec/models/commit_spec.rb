# frozen_string_literal: true

require "rails_helper"

RSpec.describe Commit do
  describe "validations" do
    it "requires sha" do
      commit = build(:commit, sha: nil)

      expect(commit).not_to be_valid
      expect(commit.errors[:sha]).to include("can't be blank")
    end

    it "requires unique sha" do
      create(:commit, sha: "abc123")
      dup = build(:commit, sha: "abc123")

      expect(dup).not_to be_valid
    end

    it "belongs to a repository" do
      commit = build(:commit, repository: nil)

      expect(commit).not_to be_valid
    end
  end

  describe "before_create :normalize_author_name" do
    it "normalizes author_name on creation" do
      repo = create(:repository)
      commit = create(:commit, repository: repo, author_name: "Jane Doe")

      expect(commit.normalized_author_name).to eq("jane doe")
    end

    it "skips normalization when author_name is blank" do
      repo = create(:repository)
      commit = create(:commit, repository: repo, author_name: nil)

      expect(commit.normalized_author_name).to be_nil
    end

    it "uses AuthorNameNormalizer mapping" do
      repo = create(:repository)
      allow_any_instance_of(AuthorNameNormalizer).to receive(:call)
        .with("JDoe").and_return("jane doe")

      commit = create(:commit, repository: repo, author_name: "JDoe")

      expect(commit.normalized_author_name).to eq("jane doe")
    end
  end
end
