# frozen_string_literal: true

require "rails_helper"
require "net/http"

RSpec.describe SonarCloudClient do
  subject(:client) { described_class.new(token: "test-token", organization: "test-org") }

  let(:success_response) { instance_double(Net::HTTPOK, body: response_body, code: "200") }
  let(:error_response) { instance_double(Net::HTTPUnauthorized, body: '{"errors":[{"msg":"Not authorized"}]}', code: "401") }

  before do
    allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    allow(error_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
  end

  describe "#projects" do
    let(:response_body) do
      { "paging" => { "total" => 1 }, "components" => [ { "key" => "org_repo", "name" => "repo", "lastAnalysisDate" => "2026-03-20T10:00:00+0000" } ] }.to_json
    end

    it "fetches projects from SonarCloud" do
      allow(Net::HTTP).to receive(:start).and_return(success_response)

      result = client.projects

      expect(result["components"].size).to eq(1)
      expect(result["components"].first["key"]).to eq("org_repo")
      expect(result["components"].first["lastAnalysisDate"]).to eq("2026-03-20T10:00:00+0000")
    end

    it "calls the components/search endpoint with TRK qualifier" do
      captured_uri = nil
      allow(client).to receive(:execute_request) do |uri|
        captured_uri = uri
        JSON.parse(response_body)
      end

      client.projects

      expect(captured_uri.path).to eq("/api/components/search")
      query = URI.decode_www_form(captured_uri.query).to_h
      expect(query).to include("organization" => "test-org", "qualifiers" => "TRK")
    end

    it "raises on non-200 response" do
      allow(Net::HTTP).to receive(:start).and_return(error_response)

      expect { client.projects }.to raise_error(/SonarCloud API error \(401\)/)
    end
  end

  describe "#measures" do
    let(:response_body) do
      {
        "component" => {
          "key" => "org_repo",
          "measures" => [
            { "metric" => "bugs", "value" => "3" },
            { "metric" => "coverage", "value" => "82.5" }
          ]
        }
      }.to_json
    end

    it "fetches measures for a component" do
      allow(Net::HTTP).to receive(:start).and_return(success_response)

      result = client.measures(component_key: "org_repo")
      measures = result.dig("component", "measures")

      expect(measures.size).to eq(2)
      expect(measures.first["value"]).to eq("3")
    end
  end

  describe "#issues" do
    let(:response_body) do
      {
        "paging" => { "total" => 1 },
        "issues" => [ {
          "key" => "AXyz1", "type" => "BUG", "severity" => "MAJOR",
          "status" => "OPEN", "message" => "Fix this"
        } ]
      }.to_json
    end

    it "fetches issues for a component" do
      allow(Net::HTTP).to receive(:start).and_return(success_response)

      result = client.issues(component_key: "org_repo")

      expect(result["issues"].size).to eq(1)
      expect(result["issues"].first["type"]).to eq("BUG")
    end

    it "includes createdAfter when created_after is provided" do
      captured_uri = nil
      allow(client).to receive(:execute_request) do |uri|
        captured_uri = uri
        JSON.parse(response_body)
      end

      since = Time.utc(2026, 3, 20, 10, 0, 0)
      client.issues(component_key: "org_repo", created_after: since)

      query = URI.decode_www_form(captured_uri.query).to_h
      expect(query).to include("createdAfter" => "2026-03-20T10:00:00+0000")
    end
  end

  describe "retries" do
    let(:response_body) { { "components" => [] }.to_json }

    before { allow(client).to receive(:sleep) }

    it "retries on timeout and succeeds" do
      call_count = 0
      allow(Net::HTTP).to receive(:start) do
        call_count += 1
        raise Net::ReadTimeout if call_count < 3

        success_response
      end

      result = client.projects
      expect(result["components"]).to eq([])
      expect(call_count).to eq(3)
    end

    it "raises after exhausting all retries" do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)

      expect { client.projects }.to raise_error(Net::OpenTimeout)
      expect(Net::HTTP).to have_received(:start).exactly(3).times
    end

    it "does not retry on non-retryable errors" do
      allow(Net::HTTP).to receive(:start).and_return(error_response)

      expect { client.projects }.to raise_error(/SonarCloud API error/)
      expect(Net::HTTP).to have_received(:start).once
    end

    it "applies exponential backoff between retries" do
      allow(Net::HTTP).to receive(:start).and_raise(Errno::ECONNRESET)

      expect { client.projects }.to raise_error(Errno::ECONNRESET)
      expect(client).to have_received(:sleep).with(2).ordered
      expect(client).to have_received(:sleep).with(4).ordered
    end
  end
end
