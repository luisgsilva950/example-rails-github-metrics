# Responsável por normalizar nomes de autores de commits.
# Segue princípios de Sandi Metz: classes pequenas, responsabilidade única,
# poucas linhas por método público.
class AuthorNameMappings
  # Espera formato: "variant1:Canonical,variant2:Canonical".
  # Ignora entradas inválidas silenciosamente para robustez em dev.
  def initialize(raw_mapping: ENV.fetch("GITHUB_AUTHOR_NAME_MAPPINGS", ""))
    @raw_mapping = raw_mapping.to_s
  end

  def to_h
    @to_h ||= begin
      return {} if @raw_mapping.strip.empty?
      entries = @raw_mapping.split(",")
      entries.each_with_object({}) do |pair, acc|
        variant, canonical = pair.split(":", 2)
        next if variant.nil? || canonical.nil?
        acc[variant.to_s.downcase.strip] = canonical.to_s.strip
      end.freeze
    end
  end
end

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
