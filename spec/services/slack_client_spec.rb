# frozen_string_literal: true

require "rails_helper"

RSpec.describe SlackClient do
  let(:web_client) { instance_double(Slack::Web::Client) }

  before do
    # Prevent actual Slack configuration
    allow(Slack).to receive(:configure).and_yield(double("Config", logger: nil).as_null_object)
  end

  subject(:client) { described_class.new(token: "xoxb-fake-token", web_client: web_client) }

  describe "#channel_info" do
    it "returns channel info" do
      channel = double("Channel", id: "C123", name: "general")
      response = double("Response", channel: channel)
      allow(web_client).to receive(:conversations_info).with(channel: "C123").and_return(response)

      result = client.channel_info("C123")

      expect(result).to eq(channel)
    end

    it "returns nil on Slack error" do
      allow(web_client).to receive(:conversations_info).and_raise(
        Slack::Web::Api::Errors::SlackError.new("channel_not_found")
      )

      expect(client.channel_info("C999")).to be_nil
    end
  end

  describe "#channel_messages" do
    it "returns messages and next_cursor" do
      msg = double("Message", text: "Hello")
      metadata = double("Metadata", next_cursor: "cursor_abc")
      response = double("Response", messages: [ msg ], response_metadata: metadata)
      allow(web_client).to receive(:conversations_history).and_return(response)

      result = client.channel_messages("C123")

      expect(result[:messages]).to eq([ msg ])
      expect(result[:next_cursor]).to eq("cursor_abc")
    end

    it "handles nil next_cursor" do
      msg = double("Message", text: "Hello")
      metadata = double("Metadata", next_cursor: "")
      response = double("Response", messages: [ msg ], response_metadata: metadata)
      allow(web_client).to receive(:conversations_history).and_return(response)

      result = client.channel_messages("C123")

      expect(result[:next_cursor]).to be_nil
    end

    it "passes cursor, oldest, latest params" do
      metadata = double("Metadata", next_cursor: nil)
      response = double("Response", messages: [], response_metadata: metadata)
      allow(web_client).to receive(:conversations_history).with(
        hash_including(channel: "C123", cursor: "cur1", oldest: "1000", latest: "2000")
      ).and_return(response)

      result = client.channel_messages("C123", cursor: "cur1", oldest: "1000", latest: "2000")

      expect(result[:messages]).to eq([])
    end

    it "returns empty on Slack error" do
      allow(web_client).to receive(:conversations_history).and_raise(
        Slack::Web::Api::Errors::SlackError.new("channel_not_found")
      )

      result = client.channel_messages("C123")

      expect(result[:messages]).to eq([])
      expect(result[:next_cursor]).to be_nil
    end
  end

  describe "#enumerate_channel_messages" do
    it "paginates all messages" do
      msg1 = double("Message1", text: "Page 1")
      msg2 = double("Message2", text: "Page 2")

      allow(client).to receive(:channel_messages)
        .with("C123", limit: 200, cursor: nil, oldest: nil, latest: nil)
        .and_return({ messages: [ msg1 ], next_cursor: "cursor2" })

      allow(client).to receive(:channel_messages)
        .with("C123", limit: 200, cursor: "cursor2", oldest: nil, latest: nil)
        .and_return({ messages: [ msg2 ], next_cursor: nil })

      result = client.enumerate_channel_messages("C123")

      expect(result).to eq([ msg1, msg2 ])
    end

    it "respects max_pages limit" do
      msg = double("Message", text: "Only Page")

      allow(client).to receive(:channel_messages)
        .and_return({ messages: [ msg ], next_cursor: "next" })

      result = client.enumerate_channel_messages("C123", max_pages: 1)

      expect(result).to eq([ msg ])
    end

    it "stops when next_cursor is empty string" do
      msg = double("Message", text: "Last page")

      allow(client).to receive(:channel_messages)
        .and_return({ messages: [ msg ], next_cursor: "" })

      result = client.enumerate_channel_messages("C123")

      expect(result).to eq([ msg ])
    end
  end

  describe "token resolution" do
    it "uses ENV token when no token provided" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SLACK_BOT_TOKEN").and_return("xoxb-env-token")

      c = described_class.new(web_client: web_client)
      expect(c).to be_a(SlackClient)
    end

    it "raises when no token available" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("SLACK_BOT_TOKEN").and_return(nil)

      # Mock credentials to not have slack token
      credentials = double("Credentials")
      allow(credentials).to receive(:dig).with(:slack, :bot_token).and_return(nil)
      allow(Rails.application).to receive(:credentials).and_return(credentials)

      expect { described_class.new(web_client: web_client) }.to raise_error(/Slack bot token not configured/)
    end
  end
end
