class GithubClient
  require "faraday"
  require "thread"

  DEFAULT_MAX_RETRIES      = Integer(ENV.fetch("GITHUB_API_RETRY_MAX", 15))
  DEFAULT_RETRY_INTERVAL   = Float(ENV.fetch("GITHUB_API_RETRY_INTERVAL", 0.5))
  DEFAULT_BACKOFF_FACTOR   = Float(ENV.fetch("GITHUB_API_RETRY_BACKOFF", 2.0))
  OPEN_TIMEOUT_SECONDS     = Integer(ENV.fetch("GITHUB_OPEN_TIMEOUT", 5))
  READ_TIMEOUT_SECONDS     = Integer(ENV.fetch("GITHUB_READ_TIMEOUT", 60))
  DEFAULT_PR_DETAILS_THREADS = Integer(ENV.fetch("GITHUB_PR_DETAILS_THREADS", 1))

  def initialize(api_client: build_octokit_client)
    @api_client = api_client
    @api_client.auto_paginate = true
    @api_client.per_page = 2000
  end

  def repositories_for_team(team_slug)
    org, team = extract_org_and_team(team_slug)
    return [] if org.nil? || team.nil?
    team_obj = find_team_by_slug(org, team)
    return [] unless team_obj
    @api_client.team_repos(team_obj.id).map(&:full_name)
  rescue Octokit::NotFound => e
    puts "404 error when fetching repositories for team #{team_slug}: #{e.message}"
    puts "Expected format: org/team_slug (e.g., syngenta-digital/cropwise-core-services)"
    Rails.logger.warn "Time não encontrado ou acesso negado: #{team_slug}"
    []
  end

  def repository_details(repo_name)
    @api_client.repo(repo_name)
  end

  def commits_for_repo(repo_name)
    last_year = (Time.now - 1.year).iso8601
    @api_client.commits_since(repo_name, last_year)
  rescue Octokit::Conflict => e
    puts "Error fetching commits for repository #{repo_name}: #{e.message}"
    []
  end

  def pull_requests_for_repo(repo_name)
    @api_client.pull_requests(repo_name, state: "all")
  rescue Octokit::Conflict => e
    puts "Error fetching pull requests for repository #{repo_name}: #{e.message}"
    []
  end

  def pull_request_details(repo_name, number)
    @api_client.pull_request(repo_name, number)
  rescue Octokit::NotFound
    nil
  end

  def pull_request_details_batch(repo_name, numbers, max_threads: DEFAULT_PR_DETAILS_THREADS)
    pr_numbers = Array(numbers).compact.uniq
    return {} if pr_numbers.empty?

    queue = Queue.new
    pr_numbers.each { |num| queue << num }

    results = {}
    mutex = Mutex.new
    worker_count = [ queue.size, max_threads.to_i, 1 ].max.clamp(1, pr_numbers.size)

    threads = Array.new(worker_count) do
      Thread.new do
        loop do
          number = queue.pop(true) rescue break
          begin
            detail = pull_request_details(repo_name, number)
            mutex.synchronize { results[number] = detail }
          rescue StandardError => e
            Rails.logger.warn "Falha ao buscar detalhes do PR ##{number} em #{repo_name}: #{e.message}"
            mutex.synchronize { results[number] = nil }
          end
        end
      end
    end

    threads.each(&:join)
    results
  end

  private

  def extract_org_and_team(input)
    parts = input.to_s.split("/")
    return [ parts[0], parts[1] ] if parts.size == 2
    if parts.size == 3 && parts[1] == "teams"
      return [ parts[0], parts[2] ]
    end
    [ nil, nil ]
  end

  def org_teams(org)
    @org_teams_cache ||= {}
    @org_teams_cache[org] ||= @api_client.org_teams(org)
  end

  def find_team_by_slug(org, team_slug)
    teams = org_teams(org)
    teams.find { |t| t.slug == team_slug }
  rescue Octokit::NotFound
    nil
  end

  def build_octokit_client
    middleware_stack = Faraday::RackBuilder.new do |builder|
      if defined?(Faraday::Retry::Middleware)
        builder.use Faraday::Retry::Middleware, {
          max: DEFAULT_MAX_RETRIES,
          interval: DEFAULT_RETRY_INTERVAL,
          backoff_factor: DEFAULT_BACKOFF_FACTOR,
          methods: %i[get head options put post],
          retry_statuses: [ 429, 500, 502, 503, 504 ],
          exceptions: [ Faraday::ConnectionFailed, Faraday::TimeoutError ]
        }
      end
      builder.use Octokit::Middleware::FollowRedirects
      builder.use Octokit::Response::RaiseError
      builder.adapter Faraday.default_adapter
    end

    Octokit::Client.new(
      access_token: ENV["GITHUB_TOKEN"],
      middleware: middleware_stack,
      connection_options: {
        request: {
          open_timeout: OPEN_TIMEOUT_SECONDS,
          timeout: READ_TIMEOUT_SECONDS
        }
      }
    )
  end
end
