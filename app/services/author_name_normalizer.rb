class AuthorNameNormalizer
  def initialize(mappings: AuthorNameMappings.new)
    @mappings = mappings
  end

  def call(name)
    return nil if name.nil?
    n = canonical_for(name) || name.strip
    n.to_s.downcase.strip
  end

  private

  def canonical_for(name)
    @mappings.to_h[name.to_s.downcase.strip]
  end
end
