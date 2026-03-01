# frozen_string_literal: true

require "rails_helper"

RSpec.describe CategoriesNormalizer do
  describe "#call" do
    it "returns unchanged result when no rules apply" do
      result = described_class.new([ "feature:login" ]).call

      expect(result[:normalized]).to eq([ "feature:login" ])
      expect(result[:added]).to be_empty
      expect(result[:removed]).to be_empty
      expect(result[:changed?]).to be false
    end

    it "handles nil input gracefully" do
      result = described_class.new(nil).call

      expect(result[:normalized]).to eq([])
      expect(result[:changed?]).to be false
    end

    it "handles empty categories" do
      result = described_class.new([]).call

      expect(result[:normalized]).to eq([])
      expect(result[:changed?]).to be false
    end

    context "cw_elements_ prefix rule" do
      it "adds mfe: prefix to cw_elements_ categories" do
        result = described_class.new([ "cw_elements_login" ]).call

        expect(result[:normalized]).to include("mfe:cw_elements_login")
        expect(result[:normalized]).not_to include("cw_elements_login")
        expect(result[:added]).to include("mfe:cw_elements_login")
        expect(result[:removed]).to include("cw_elements_login")
        expect(result[:changed?]).to be true
      end

      it "skips when mfe: prefix already exists" do
        result = described_class.new([ "cw_elements_login", "mfe:cw_elements_login" ]).call

        expect(result[:normalized]).to include("mfe:cw_elements_login")
        expect(result[:removed]).not_to include("cw_elements_login")
      end

      it "adds project:cw_elements automatically" do
        result = described_class.new([ "cw_elements_login" ]).call

        expect(result[:normalized]).to include("project:cw_elements")
      end
    end

    context "_api suffix rule" do
      it "adds feature: prefix to _api categories" do
        result = described_class.new([ "weather_api" ]).call

        expect(result[:normalized]).to include("feature:weather_api")
        expect(result[:normalized]).not_to include("weather_api")
        expect(result[:changed?]).to be true
      end

      it "skips when feature: prefix already exists" do
        result = described_class.new([ "feature:weather_api" ]).call

        expect(result[:removed]).not_to include("feature:weather_api")
      end

      it "does not duplicate when both exist" do
        result = described_class.new([ "weather_api", "feature:weather_api" ]).call

        expect(result[:normalized]).to include("feature:weather_api")
        expect(result[:removed]).not_to include("weather_api")
      end
    end

    context "data_integrity_ prefix rule" do
      it "transforms data_integrity_ to data_integrity_reason:" do
        result = described_class.new([ "data_integrity_duplicate" ]).call

        expect(result[:normalized]).to include("data_integrity_reason:duplicate")
        expect(result[:normalized]).not_to include("data_integrity_duplicate")
        expect(result[:changed?]).to be true
      end

      it "skips data_integrity_reason: labels" do
        result = described_class.new([ "data_integrity_reason:duplicate" ]).call

        expect(result[:removed]).not_to include("data_integrity_reason:duplicate")
      end

      it "does not duplicate when target already exists" do
        input = [ "data_integrity_duplicate", "data_integrity_reason:duplicate" ]
        result = described_class.new(input).call

        expect(result[:removed]).not_to include("data_integrity_duplicate")
      end
    end

    context "map_integrator prefix rule" do
      it "adds feature: prefix to map_integrator categories" do
        result = described_class.new([ "map_integrator_v2" ]).call

        expect(result[:normalized]).to include("feature:map_integrator_v2")
        expect(result[:normalized]).to include("project:map_integrator")
        expect(result[:changed?]).to be true
      end

      it "skips when feature: prefix already exists" do
        result = described_class.new([ "feature:map_integrator_v2" ]).call

        expect(result[:normalized]).to include("project:map_integrator")
        expect(result[:removed]).not_to include("feature:map_integrator_v2")
      end

      it "does not duplicate when both exist" do
        input = [ "map_integrator_v2", "feature:map_integrator_v2" ]
        result = described_class.new(input).call

        expect(result[:normalized]).to include("feature:map_integrator_v2")
        expect(result[:removed]).not_to include("map_integrator_v2")
      end
    end

    context "cw_farm_settings prefix rule" do
      it "adds feature: prefix to cw_farm_settings categories" do
        result = described_class.new([ "cw_farm_settings_v1" ]).call

        expect(result[:normalized]).to include("feature:cw_farm_settings_v1")
        expect(result[:normalized]).to include("project:cw_farm_settings")
        expect(result[:changed?]).to be true
      end

      it "does not duplicate when both exist" do
        input = [ "cw_farm_settings_v1", "feature:cw_farm_settings_v1" ]
        result = described_class.new(input).call

        expect(result[:normalized]).to include("feature:cw_farm_settings_v1")
        expect(result[:removed]).not_to include("cw_farm_settings_v1")
      end
    end

    context "project rules" do
      it "replaces project:cw-elements with project:cw_elements" do
        result = described_class.new([ "project:cw-elements" ]).call

        expect(result[:normalized]).to include("project:cw_elements")
        expect(result[:normalized]).not_to include("project:cw-elements")
        expect(result[:changed?]).to be true
      end

      it "adds project:cw_farm_settings when cw_farm_settings category exists" do
        result = described_class.new([ "cw_farm_settings_v1" ]).call

        expect(result[:normalized]).to include("project:cw_farm_settings")
        expect(result[:normalized]).to include("feature:cw_farm_settings_v1")
      end

      it "adds project:map_integrator when map_integrator category exists" do
        result = described_class.new([ "map_integrator_v2" ]).call

        expect(result[:normalized]).to include("project:map_integrator")
      end
    end

    context "label replacements" do
      it "replaces Strix with project:strix" do
        result = described_class.new([ "Strix" ]).call

        expect(result[:normalized]).to include("project:strix")
        expect(result[:normalized]).not_to include("Strix")
        expect(result[:changed?]).to be true
      end

      it "does not duplicate if project:strix already exists" do
        result = described_class.new([ "Strix", "project:strix" ]).call

        expect(result[:removed]).not_to include("Strix")
      end

      it "replaces cup with project:cup" do
        result = described_class.new([ "cup" ]).call

        expect(result[:normalized]).to include("project:cup")
        expect(result[:normalized]).not_to include("cup")
        expect(result[:changed?]).to be true
      end

      it "does not duplicate if project:cup already exists" do
        result = described_class.new([ "cup", "project:cup" ]).call

        expect(result[:removed]).not_to include("cup")
      end
    end

    context "duplicated feature: prefixes" do
      it "fixes feature:feature: to feature:" do
        result = described_class.new([ "feature:feature:login" ]).call

        expect(result[:normalized]).to include("feature:login")
        expect(result[:normalized]).not_to include("feature:feature:login")
      end
    end

    context "complex mixed input" do
      it "applies multiple rules at once" do
        input = [
          "cw_elements_button",
          "weather_api",
          "data_integrity_null_field",
          "Strix",
          "cup",
          "feature:login"
        ]

        result = described_class.new(input).call

        expect(result[:normalized]).to include("mfe:cw_elements_button")
        expect(result[:normalized]).to include("project:cw_elements")
        expect(result[:normalized]).to include("feature:weather_api")
        expect(result[:normalized]).to include("data_integrity_reason:null_field")
        expect(result[:normalized]).to include("project:strix")
        expect(result[:normalized]).to include("project:cup")
        expect(result[:normalized]).to include("feature:login")
        expect(result[:changed?]).to be true
      end
    end
  end
end
