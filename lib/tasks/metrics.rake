namespace :metrics do
  desc "Extrai métricas do GitHub (commits, repositórios) dos times e repos definidos"
  task extract: :environment do
    puts "Iniciando a extração de métricas do GitHub..."

    client = GithubClient.new

    puts "Inicializando configuração com variáveis de ambiente... Ambiente: #{ENV['RAILS_ENV']}"
    config = MetricsConfiguration.new(env: ENV)
    puts "Times configurados: #{config.team_slugs.join(', ')}"
    puts "Repositórios explícitos configurados: #{config.explicit_repo_names.join(', ')}"
    
    MetricsExtractor.new(client: client, configuration: config).call

    puts "Extração concluída."
    puts "Novos commits salvos: #{Commit.where('created_at > ?', 2.minutes.ago).count}"
    puts "Total de repositórios monitorados: #{Repository.count}"
  end
end

namespace :jira do
  desc 'Extrai bugs do Jira usando JQL. Parametros: JQL, MAX_RESULTS (opcional)'
  task extract_bugs: :environment do
    jql = ENV['JIRA_BUGS_JQL'] || 'project = YOURPROJECT AND issuetype = Bug ORDER BY created DESC'
    max_results = Integer(ENV.fetch('JIRA_MAX_RESULTS', 500))
    fields = ENV['JIRA_FIELDS']
    expand = ENV['JIRA_EXPAND']
    fetch_full = ENV['JIRA_FETCH_FULL']

    require 'jira-ruby'
    client = JiraClient.new
    issues = client.search_issues(jql, max_results: max_results, fields: fields, expand: expand, fetch_full: fetch_full)
    puts "Issues retornadas (#{issues.size}). Salvando..."
    extractor = JiraBugsExtractor.new(client: client, jql: jql, max_results: max_results)
    extractor.save_issues(issues)
    puts 'Extração de bugs do Jira concluída.'
  end
end
