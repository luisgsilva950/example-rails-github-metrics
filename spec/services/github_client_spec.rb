# frozen_string_literal: true

require "rails_helper"

RSpec.describe GithubClient do
  let(:octokit) { instance_double(Octokit::Client) }

  before do
    allow(octokit).to receive(:auto_paginate=)
    allow(octokit).to receive(:per_page=)
  end

  subject(:client) { described_class.new(api_client: octokit) }

  describe "#repositories_for_team" do
    it "returns repository full names for a valid team" do
      team = double("Team", id: 42, slug: "core-team")
      repo1 = double("Repo", full_name: "org/repo1")
      repo2 = double("Repo", full_name: "org/repo2")

      allow(octokit).to receive(:org_teams).with("org").and_return([team])
      allow(octokit).to receive(:team_repos).with(42).and_return([repo1, repo2])

      result = client.repositories_for_team("org/core-team")

      expect(result).to eq(["org/repo1", "org/repo2"])
    end

    it "returns empty array when team is not found" do
      team = double("Team", id: 1, slug: "other-team")
      allow(octokit).to receive(:org_teams).with("org").and_return([team])

      result = client.repositories_for_team("org/unknown-team")

      expect(result).to eq([])
    end

    it "returns empty array for invalid input format" do
      result = client.repositories_for_team("no-slash")

      expect(result).to eq([])
    end

    it "handles org/teams/slug format" do
      team = double("Team", id: 10, slug: "my-team")
      repo = double("Repo", full_name: "org/repo")

      allow(octokit).to receive(:org_teams).with("org").and_return([team])
      allow(octokit).to receive(:team_repos).with(10).and_return([repo])

      result = client.repositories_for_team("org/teams/my-team")

      expect(result).to eq(["org/repo"])
    end

    it "handles Octokit::NotFound" do
      allow(octokit).to receive(:org_teams).and_raise(Octokit::NotFound.new)

      result = client.repositories_for_team("org/team")

      expect(result).to eq([])
    end
  end

  describe "#repository_details" do
    it "returns repository data" do
      repo_data = double("Repo", full_name: "org/repo")
      allow(octokit).to receive(:repo).with("org/repo").and_return(repo_data)

      expect(client.repository_details("org/repo")).to eq(repo_data)
    end
  end

  describe "#commits_for_repo" do
    it "returns commits from last year" do
      commit = double("Commit", sha: "abc123")
      allow(octokit).to receive(:commits_since).and_return([commit])

      result = client.commits_for_repo("org/repo")

      expect(result).to eq([commit])
    end

    it "returns empty on Octokit::Conflict" do
      allow(octokit).to receive(:commits_since).and_raise(Octokit::Conflict.new)

      expect(client.commits_for_repo("org/repo")).to eq([])
    end
  end

  describe "#pull_requests_for_repo" do
    it "returns all pull requests" do
      pr = double("PR", number: 1)
      allow(octokit).to receive(:pull_requests).with("org/repo", state: "all").and_return([pr])

      expect(client.pull_requests_for_repo("org/repo")).to eq([pr])
    end

    it "returns empty on Octokit::Conflict" do
      allow(octokit).to receive(:pull_requests).and_raise(Octokit::Conflict.new)

      expect(client.pull_requests_for_repo("org/repo")).to eq([])
    end
  end

  describe "#pull_request_details" do
    it "returns PR details" do
      pr = double("PR", number: 5)
      allow(octokit).to receive(:pull_request).with("org/repo", 5).and_return(pr)

      expect(client.pull_request_details("org/repo", 5)).to eq(pr)
    end

    it "returns nil on Octokit::NotFound" do
      allow(octokit).to receive(:pull_request).and_raise(Octokit::NotFound.new)

      expect(client.pull_request_details("org/repo", 999)).to be_nil
    end
  end

  describe "#pull_request_details_batch" do
    it "returns a hash of PR details by number" do
      pr1 = double("PR", number: 1)
      pr2 = double("PR", number: 2)
      allow(octokit).to receive(:pull_request).with("org/repo", 1).and_return(pr1)
      allow(octokit).to receive(:pull_request).with("org/repo", 2).and_return(pr2)

      result = client.pull_request_details_batch("org/repo", [1, 2], max_threads: 1)

      expect(result[1]).to eq(pr1)
      expect(result[2]).to eq(pr2)
    end

    it "returns empty hash for empty numbers" do
      expect(client.pull_request_details_batch("org/repo", [])).to eq({})
    end

    it "returns nil for failed PR fetches" do
      allow(octokit).to receive(:pull_request).and_raise(StandardError.new("fail"))

      result = client.pull_request_details_batch("org/repo", [1], max_threads: 1)

      expect(result[1]).to be_nil
    end

    it "deduplicates PR numbers" do
      pr = double("PR", number: 5)
      allow(octokit).to receive(:pull_request).with("org/repo", 5).and_return(pr)

      result = client.pull_request_details_batch("org/repo", [5, 5, 5], max_threads: 1)

      expect(result.size).to eq(1)
    end
  end
end
