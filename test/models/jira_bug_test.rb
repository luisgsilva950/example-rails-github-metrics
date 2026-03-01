require "test_helper"

class JiraBugTest < ActiveSupport::TestCase
  test "valid bug" do
    bug = JiraBug.new(issue_key: "BUG-123", title: "Falha X", opened_at: Time.now)
    assert bug.valid?, bug.errors.full_messages.join(", ")
  end

  test "requires fields" do
    bug = JiraBug.new
    refute bug.valid?
    assert_includes bug.errors[:issue_key], "can't be blank"
    assert_includes bug.errors[:title], "can't be blank"
    assert_includes bug.errors[:opened_at], "can't be blank"
  end

  test "unique issue_key" do
    JiraBug.create!(issue_key: "BUG-999", title: "Um bug", opened_at: Time.now)
    dup = JiraBug.new(issue_key: "BUG-999", title: "Outro bug", opened_at: Time.now)
    refute dup.valid?
    assert_includes dup.errors[:issue_key], "has already been taken"
  end
end

