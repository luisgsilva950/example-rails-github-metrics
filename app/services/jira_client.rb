require "jira-ruby"
require "openssl"
require "certifi"
# Classe isoladora para interação com a API do Jira
# Usa a gem jira-ruby
class JiraClient
  def initialize(options = {})
    @site         = options.fetch(:site) { ENV.fetch("JIRA_SITE") }
    @username     = options.fetch(:username) { ENV.fetch("JIRA_USERNAME") }
    @api_token    = options.fetch(:api_token) { ENV.fetch("JIRA_API_TOKEN") }
    @context_path = options.fetch(:context_path, "")
    @use_ssl      = options.fetch(:use_ssl, true)
    # Verificação SSL (por padrão habilitada). Para desativar: JIRA_VERIFY_SSL=0 ou false
    @verify_ssl   = options.fetch(:verify_ssl) do
      raw = ENV.fetch("JIRA_VERIFY_SSL", "true").downcase
      !(%w[0 false no off].include?(raw))
    end
    @ssl_cert_file = options.fetch(:ssl_cert_file) { ENV["JIRA_SSL_CERT_FILE"] }
    @ssl_cert_path = options.fetch(:ssl_cert_path) { ENV["JIRA_SSL_CERT_PATH"] }
    @client = build_client
  end

  # Retorna issues para um JQL fornecido
  def search_issues(jql, max_results: 100, fields: nil, expand: nil, fetch_full: nil)
    fields ||= ENV["JIRA_FIELDS"].presence || "*all" # Jira aceita '*all' para retornar todos os campos
    expand ||= ENV["JIRA_EXPAND"].presence            # Ex: 'changelog,renderedFields'

    fetch_full = if fetch_full.nil?
      raw = ENV.fetch("JIRA_FETCH_FULL", "true").downcase
      !(%w[0 false no off].include?(raw))
    else
      fetch_full
    end

    options = { max_results: max_results }
    options[:expand] = expand if expand

    issues = @client.Issue.jql(jql, options)
    puts "Total issues found for JQL '#{jql}': #{issues.size}"
    return issues unless fetch_full
    issues.map { |issue| safe_fetch_issue(issue.id, fields: fields, expand: expand) }
  rescue StandardError => e
    Rails.logger.error "Erro ao buscar issues Jira: #{e.message}"
    []
  end

  def fetch_issue(key, fields: nil, expand: nil)
    puts "Fetching Jira issue: #{key}"
    fields ||= ENV["JIRA_FIELDS"].presence || "*all"
    params = { fields: fields }
    params[:expand] = expand if expand
    @client.Issue.find(key)
  rescue StandardError => e
    Rails.logger.error "Erro ao buscar issue #{key}: #{e.message}"
    nil
  end

  def create_issue(fields:)
    path = "#{@client.options[:rest_base_path]}/issue"
    response = @client.post(path, { "fields" => fields }.to_json)
    JSON.parse(response.body)["key"]
  end

  def link_issues(inward_key:, outward_key:, link_type: "Cloners")
    path = "#{@client.options[:rest_base_path]}/issueLink"
    body = {
      "type" => { "name" => link_type },
      "inwardIssue" => { "key" => inward_key },
      "outwardIssue" => { "key" => outward_key }
    }
    @client.post(path, body.to_json)
  end

  private

  def build_client
    config = {
      site: @site,
      context_path: @context_path,
      auth_type: :basic,
      username: @username,
      password: @api_token,
      use_ssl: @use_ssl
    }

    unless @verify_ssl
      config[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE
      Rails.logger.warn "[JiraClient] SSL verification DESATIVADA. Use apenas para depuração."
    end

    # if @ssl_cert_file.present?
    #   config[:ssl_cert_file] = @ssl_cert_file
    # elsif @ssl_cert_path.present?
    #   config[:ssl_cert_path] = @ssl_cert_path
    # else
    #   # Usa bundle de CAs Mozilla do certifi (comportamento similar ao requests em Python)
    #   config[:ssl_cert_file] = Certifi.where
    # end

    JIRA::Client.new(config)
  rescue OpenSSL::SSL::SSLError => e
    Rails.logger.error "[JiraClient] Erro SSL ao inicializar cliente Jira: #{e.message}"
    Rails.logger.error "Sugestões: "
    Rails.logger.error "1) Atualize certificados: brew update && brew reinstall ca-certificates"
    Rails.logger.error "2) Especifique JIRA_SSL_CERT_FILE ou JIRA_SSL_CERT_PATH se usar CA corporativa."
    Rails.logger.error "3) Temporariamente desative verificação: JIRA_VERIFY_SSL=0 (não recomendado para produção)."
    raise
  end

  def safe_fetch_issue(key, fields:, expand: nil)
    fetch_issue(key, fields: fields, expand: expand) || OpenStruct.new(key: key, fields: {})
  end
end
