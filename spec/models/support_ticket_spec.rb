# frozen_string_literal: true

require "rails_helper"

RSpec.describe SupportTicket, type: :model do
  describe "validations" do
    it "is valid with all required attributes" do
      ticket = build(:support_ticket)
      expect(ticket).to be_valid
    end

    it "is invalid without issue_key" do
      ticket = build(:support_ticket, issue_key: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:issue_key]).to include("can't be blank")
    end

    it "is invalid without title" do
      ticket = build(:support_ticket, title: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:title]).to include("can't be blank")
    end

    it "is invalid without opened_at" do
      ticket = build(:support_ticket, opened_at: nil)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:opened_at]).to include("can't be blank")
    end

    it "is invalid with duplicate issue_key" do
      create(:support_ticket, issue_key: "SUP-999")
      duplicate = build(:support_ticket, issue_key: "SUP-999")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:issue_key]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let(:team) { "Digital Farm" }
    let(:today) { Time.current.in_time_zone(SupportTicket::SAO_PAULO_TZ).to_date }

    describe ".by_team" do
      it "returns tickets for the given team" do
        ticket = create(:support_ticket, team: team)
        create(:support_ticket, team: "Other Team")

        expect(SupportTicket.by_team(team)).to eq([ ticket ])
      end
    end

    describe ".by_status" do
      it "returns tickets with the given status" do
        open_ticket = create(:support_ticket, status: "Open")
        create(:support_ticket, :closed)

        expect(SupportTicket.by_status("Open")).to eq([ open_ticket ])
      end
    end

    describe ".by_priority" do
      it "returns tickets with the given priority" do
        high = create(:support_ticket, :high_priority)
        create(:support_ticket, priority: "Low")

        expect(SupportTicket.by_priority("High")).to eq([ high ])
      end
    end

    describe ".most_recent" do
      it "orders tickets by opened_at descending" do
        old = create(:support_ticket, opened_at: 10.days.ago)
        recent = create(:support_ticket, opened_at: 1.day.ago)

        expect(SupportTicket.most_recent).to eq([ recent, old ])
      end
    end

    describe ".by_date_range" do
      it "filters tickets within the date range" do
        create(:support_ticket, opened_at: 60.days.ago)
        in_range = create(:support_ticket, opened_at: 5.days.ago)

        start_date = (today - 30.days).iso8601
        end_date = today.iso8601

        expect(SupportTicket.by_date_range(start_date, end_date)).to eq([ in_range ])
      end
    end
  end
end
