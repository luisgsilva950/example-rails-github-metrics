# frozen_string_literal: true

require "rails_helper"

RSpec.describe JiraBugs::ValidateBugCategories do
  subject(:validator) { described_class.new }

  it "returns empty for data integrity bugs" do
    categories = [ "data_integrity_reason:duplicate_records" ]

    expect(validator.call(categories)).to be_empty
  end

  it "returns missing_project when no project category" do
    categories = [ "feature:login" ]

    expect(validator.call(categories)).to include("missing_project_category")
  end

  it "returns missing_feature when no feature category" do
    categories = [ "project:auth" ]

    expect(validator.call(categories)).to include("missing_feature_category")
  end

  it "returns missing_mfe for cw_elements without mfe" do
    categories = [ "feature:login", "project:cw_elements" ]

    expect(validator.call(categories)).to include("missing_mfe_category")
  end

  it "returns empty for fully categorized bug" do
    categories = [ "feature:login", "project:auth" ]

    expect(validator.call(categories)).to be_empty
  end

  it "does not require mfe for non-cw_elements projects" do
    categories = [ "feature:login", "project:other" ]

    expect(validator.call(categories)).not_to include("missing_mfe_category")
  end
end
