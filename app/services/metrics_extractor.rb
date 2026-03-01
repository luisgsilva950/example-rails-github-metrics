class MetricsExtractor
  def initialize(client:, configuration:)
    @client = client
    @configuration = configuration
  end

  def call
    puts "Starting GitHub metrics extraction..."
    puts "Repositories to be processed: #{all_repo_names.join(', ')}"
    all_repo_names.each do |repo_name|
      puts "Extracting repository data for: #{repo_name}"
      process_repository(repo_name)
    end
  end

  private

  def all_repo_names
    team_repos = @configuration.team_slugs.flat_map do |slug|
      @client.repositories_for_team(slug)
    end

    (team_repos + @configuration.explicit_repo_names).uniq
  end

  def process_repository(repo_name)
    puts "Fetching repository details: #{repo_name}"
    repo_data = @client.repository_details(repo_name)
    puts "Processing repository: #{repo_data.full_name}"
    repo_record = save_repository(repo_data)
    if repo_record.present?
      puts "Fetching commits for repository: #{repo_record.name}"
      pr_numbers = process_commits(repo_record)
      puts "Fetching pull requests referenced in commits for repository: #{repo_record.name}"
      process_pull_requests(repo_record, pr_numbers)
    end
  rescue Octokit::NotFound => e
    puts "Error fetching repository: #{e.message}"
    puts "Repository not found or inaccessible: #{repo_name}"
    Rails.logger.error "Repositório não encontrado ou sem acesso: #{repo_name}"
  end

  def save_repository(data)
    Repository.find_or_create_by(github_id: data.id) do |repo|
      repo.name = data.full_name
      repo.language = data.language
    end
  end

  def process_commits(repo_record)
    commits = @client.commits_for_repo(repo_record.name)
    puts "Found #{commits.size} commits for repository: #{repo_record.name}"

    return [] if commits.empty?

    existing_shas = Commit.where(sha: commits.map(&:sha)).pluck(:sha).to_set
    pr_numbers = Set.new

    new_commits = commits.filter_map do |commit_data|
      commit_info = commit_data.commit
      next if commit_info.nil?
      author_info = commit_info.author

      pr_numbers.merge(extract_pr_numbers(commit_info.message))
      next if existing_shas.include?(commit_data.sha)

      Commit.new(
        sha: commit_data.sha,
        repository: repo_record,
        message: commit_info.message,
        author_name: author_info&.name,
        committed_at: author_info&.date
      )
    end

    if new_commits.any?
      Commit.transaction do
        new_commits.each(&:save!)
      end
      puts "Inserted #{new_commits.size} new commits for repository: #{repo_record.name}"
    else
      puts "No new commits to insert for repository: #{repo_record.name}"
    end

    pr_numbers.to_a
  end

  def process_pull_requests(repo_record, pr_numbers)
    pr_numbers = Array(pr_numbers).compact.map(&:to_i).uniq
    puts "Pull requests referenced in commits for repository #{repo_record.name}: #{pr_numbers.size}"

    if pr_numbers.empty?
      puts "No pull requests referenced in commits for repository: #{repo_record.name}"
      return
    end

    existing_numbers = PullRequest.where(repository_id: repo_record.id, number: pr_numbers).pluck(:number).to_set

    new_pull_requests = pr_numbers.filter_map do |pr_number|
      next if existing_numbers.include?(pr_number)
      puts "Fetching pull request ##{pr_number} details for repository: #{repo_record.name}"
      details = @client.pull_request_details(repo_record.name, pr_number)
      next unless details

      pr = PullRequest.new(
        github_id: details.id,
        repository: repo_record,
        number: details.number,
        title: details.title,
        state: details.state,
        author_login: details.user&.login,
        author_name: details.user&.login,
        opened_at: details.created_at,
        closed_at: details.closed_at,
        merged_at: details.respond_to?(:merged_at) ? details.merged_at : nil,
        additions: details.respond_to?(:additions) ? details.additions : nil,
        deletions: details.respond_to?(:deletions) ? details.deletions : nil,
        changed_files: details.respond_to?(:changed_files) ? details.changed_files : nil
      )
      pr.save!
    end

    if new_pull_requests.any?
      puts "Inserted #{new_pull_requests.size} new pull requests for repository: #{repo_record.name}"
    else
      puts "No new pull requests to insert for repository: #{repo_record.name}"
    end
  end

  def extract_pr_numbers(message)
    message.to_s.scan(/#(\d+)/).flatten.map { |number| number.to_i }
  end
end
