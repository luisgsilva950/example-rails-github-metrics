# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetricsExtractor do
  let(:github_client) { instance_double(GithubClient) }
  let(:configuration) { instance_double(MetricsConfiguration, team_slugs: [], explicit_repo_names: ["org/repo"]) }

  subject(:extractor) { described_class.new(client: github_client, configuration: configuration) }

  describe "#call" do
    it "processes each repository from configuration" do
      repo_data = double("Repo", id: 1, full_name: "org/repo", language: "Ruby")
      repo_record = create(:repository, github_id: 1, name: "org/repo")

      allow(github_client).to receive(:repository_details).with("org/repo").and_return(repo_data)
      allow(github_client).to receive(:commits_for_repo).with("org/repo").and_return([])

      extractor.call

      expect(Repository.find_by(github_id: 1)).to be_present
    end

    it "combines team repos and explicit repos" do
      allow(configuration).to receive(:team_slugs).and_return(["org/team"])
      allow(configuration).to receive(:explicit_repo_names).and_return(["org/explicit"])
      allow(github_client).to receive(:repositories_for_team).with("org/team").and_return(["org/team-repo"])

      repo1 = double("Repo", id: 1, full_name: "org/team-repo", language: "Ruby")
      repo2 = double("Repo", id: 2, full_name: "org/explicit", language: "JS")

      allow(github_client).to receive(:repository_details).with("org/team-repo").and_return(repo1)
      allow(github_client).to receive(:repository_details).with("org/explicit").and_return(repo2)
      allow(github_client).to receive(:commits_for_repo).and_return([])

      extractor.call

      expect(Repository.count).to eq(2)
    end

    it "handles Octokit::NotFound for repositories" do
      allow(github_client).to receive(:repository_details).and_raise(Octokit::NotFound.new)

      expect { extractor.call }.not_to raise_error
    end
  end

  describe "process_commits" do
    let(:repo_record) { create(:repository, name: "org/repo") }

    it "saves new commits and extracts PR numbers" do
      commit_info = double("CommitInfo",
        message: "Fix bug (#42) and refs #99",
        author: double("Author", name: "John", date: Time.current)
      )
      commit_data = double("CommitData", sha: "abc123", commit: commit_info)

      allow(github_client).to receive(:commits_for_repo).with("org/repo").and_return([commit_data])

      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).with("org/repo").and_return(repo_data)
      allow(github_client).to receive(:pull_request_details).and_return(nil)

      extractor.call

      expect(Commit.find_by(sha: "abc123")).to be_present
    end

    it "skips existing commits" do
      create(:commit, sha: "existing", repository: repo_record)

      commit_info = double("CommitInfo",
        message: "Old commit",
        author: double("Author", name: "Jane", date: Time.current)
      )
      commit_data = double("CommitData", sha: "existing", commit: commit_info)

      allow(github_client).to receive(:commits_for_repo).with("org/repo").and_return([commit_data])

      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).with("org/repo").and_return(repo_data)

      expect { extractor.call }.not_to change(Commit, :count)
    end

    it "handles empty commits" do
      allow(github_client).to receive(:commits_for_repo).with("org/repo").and_return([])
      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).with("org/repo").and_return(repo_data)

      expect { extractor.call }.not_to change(Commit, :count)
    end

    it "handles commit with nil commit info" do
      commit_data = double("CommitData", sha: "nil_info", commit: nil)

      allow(github_client).to receive(:commits_for_repo).with("org/repo").and_return([commit_data])
      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).with("org/repo").and_return(repo_data)

      expect { extractor.call }.not_to raise_error
    end
  end

  describe "process_pull_requests" do
    let(:repo_record) { create(:repository, name: "org/repo") }

    it "saves new pull requests referenced in commits" do
      commit_info = double("CommitInfo",
        message: "Merge PR #10",
        author: double("Author", name: "John", date: Time.current)
      )
      commit_data = double("CommitData", sha: "prsha1", commit: commit_info)

      pr_details = double("PR",
        id: 500,
        number: 10,
        title: "Fix issue",
        state: "closed",
        user: double("User", login: "john"),
        created_at: 2.days.ago,
        closed_at: 1.day.ago,
        merged_at: 1.day.ago,
        additions: 10,
        deletions: 5,
        changed_files: 3
      )
      allow(pr_details).to receive(:respond_to?).and_return(true)

      allow(github_client).to receive(:commits_for_repo).and_return([commit_data])
      allow(github_client).to receive(:pull_request_details).with("org/repo", 10).and_return(pr_details)

      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).and_return(repo_data)

      extractor.call

      pr = PullRequest.find_by(number: 10)
      expect(pr).to be_present
      expect(pr.title).to eq("Fix issue")
    end

    it "skips existing pull requests" do
      create(:pull_request, number: 20, repository: repo_record, github_id: 600)

      commit_info = double("CommitInfo",
        message: "Merge PR #20",
        author: double("Author", name: "John", date: Time.current)
      )
      commit_data = double("CommitData", sha: "prsha2", commit: commit_info)

      allow(github_client).to receive(:commits_for_repo).and_return([commit_data])

      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).and_return(repo_data)

      expect { extractor.call }.not_to change(PullRequest, :count)
    end

    it "handles nil PR details" do
      commit_info = double("CommitInfo",
        message: "Merge PR #30",
        author: double("Author", name: "John", date: Time.current)
      )
      commit_data = double("CommitData", sha: "prsha3", commit: commit_info)

      allow(github_client).to receive(:commits_for_repo).and_return([commit_data])
      allow(github_client).to receive(:pull_request_details).with("org/repo", 30).and_return(nil)

      repo_data = double("Repo", id: repo_record.github_id, full_name: "org/repo", language: "Ruby")
      allow(github_client).to receive(:repository_details).and_return(repo_data)

      expect { extractor.call }.not_to change(PullRequest, :count)
    end
  end
end
