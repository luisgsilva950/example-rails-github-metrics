# frozen_string_literal: true

require "rails_helper"

RSpec.describe Team do
  subject(:team) { build(:team) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires a name" do
      team.name = nil
      expect(team).not_to be_valid
    end

    it "enforces name uniqueness" do
      create(:team, name: "Alpha")
      duplicate = build(:team, name: "Alpha")
      expect(duplicate).not_to be_valid
    end
  end

  describe "associations" do
    it "has many developers" do
      team = create(:team)
      create(:developer, team: team)
      expect(team.developers.count).to eq(1)
    end

    it "has many deliverables" do
      team = create(:team)
      create(:deliverable, team: team)
      expect(team.deliverables.count).to eq(1)
    end
  end
end
