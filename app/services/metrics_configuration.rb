# Esta classe tem a única responsabilidade de
# ler e analisar as variáveis de ambiente.
class MetricsConfiguration
  def initialize(env: ENV)
    @env = env
  end

  # Retorna uma lista dos slugs dos times
  def team_slugs
    parse_list(@env["GITHUB_TEAMS"])
  end

  # Retorna uma lista dos nomes dos repositórios
  def explicit_repo_names
    parse_list(@env["GITHUB_REPOS"])
  end

  private

  # Método pequeno, com 3 linhas (Regra da Sandi Metz)
  def parse_list(variable)
    return [] if variable.blank?
    variable.split(",").map(&:strip)
  end
end
