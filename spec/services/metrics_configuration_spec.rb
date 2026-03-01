# frozen_string_literal: true

require "rails_helper"

RSpec.describe MetricsConfiguration do
  describe "#team_slugs" do
    it "parses comma-separated teams from env" do
      config = described_class.new(env: { "GITHUB_TEAMS" => "org/team-a, org/team-b" })

      expect(config.team_slugs).to eq(["org/team-a", "org/team-b"])
    end

    it "returns empty array when env var is missing" do
      config = described_class.new(env: {})

      expect(config.team_slugs).to eq([])
    end

    it "returns empty array when env var is blank" do
      config = described_class.new(env: { "GITHUB_TEAMS" => "" })

      expect(config.team_slugs).to eq([])
    end
  end

  describe "#explicit_repo_names" do
    it "parses comma-separated repos from env" do
      config = described_class.new(env: { "GITHUB_REPOS" => "org/repo-1, org/repo-2" })

      expect(config.explicit_repo_names).to eq(["org/repo-1", "org/repo-2"])
    end

    it "returns empty array when env var is missing" do
      config = described_class.new(env: {})

      expect(config.explicit_repo_names).to eq([])
    end

    it "returns empty array when env var is blank" do
      config = described_class.new(env: { "GITHUB_REPOS" => "" })

      expect(config.explicit_repo_names).to eq([])
    end
  end
end
