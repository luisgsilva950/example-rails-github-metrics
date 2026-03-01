require "test_helper"

class AuthorNameNormalizerTest < ActiveSupport::TestCase
  test "normalizes according to mappings" do
    ENV["AUTHOR_NAME_MAPPINGS"] = "foo bar:Foo Bar,FOO:Foo Canonical,luisgsilva950:Luis Domingues"
    normalizer = AuthorNameNormalizer.new
    assert_equal "foo bar", normalizer.call("foo bar")
    assert_equal "foo canonical", normalizer.call("FOO")
    assert_equal "luis domingues", normalizer.call("luisgsilva950")
  end

  test "falls back to original when not mapped" do
    ENV["AUTHOR_NAME_MAPPINGS"] = "a:b"
    normalizer = AuthorNameNormalizer.new
    assert_equal "zed", normalizer.call("Zed")
  end

  test "returns nil for nil" do
    normalizer = AuthorNameNormalizer.new
    assert_nil normalizer.call(nil)
  end
end
