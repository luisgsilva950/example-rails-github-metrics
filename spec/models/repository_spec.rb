# frozen_string_literal: true

require "rails_helper"

RSpec.describe Repository do
  describe "validations" do
    it "requires name" do
      repo = build(:repository, name: nil)

      expect(repo).not_to be_valid
      expect(repo.errors[:name]).to include("can't be blank")
    end

    it "requires github_id" do
      repo = build(:repository, github_id: nil)

      expect(repo).not_to be_valid
      expect(repo.errors[:github_id]).to include("can't be blank")
    end

    it "requires unique name" do
      create(:repository, name: "org/repo-dup")
      dup = build(:repository, name: "org/repo-dup")

      expect(dup).not_to be_valid
    end

    it "requires unique github_id" do
      create(:repository, github_id: 999)
      dup = build(:repository, github_id: 999)

      expect(dup).not_to be_valid
    end
  end

  describe "associations" do
    it "has many commits" do
      repo = create(:repository)
      create(:commit, repository: repo)

      expect(repo.commits.count).to eq(1)
    end

    it "has many pull_requests" do
      repo = create(:repository)
      create(:pull_request, repository: repo)

      expect(repo.pull_requests.count).to eq(1)
    end

    it "destroys dependent commits" do
      repo = create(:repository)
      create(:commit, repository: repo)

      expect { repo.destroy }.to change(Commit, :count).by(-1)
    end

    it "destroys dependent pull_requests" do
      repo = create(:repository)
      create(:pull_request, repository: repo)

      expect { repo.destroy }.to change(PullRequest, :count).by(-1)
    end
  end
end
