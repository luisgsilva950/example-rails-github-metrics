# frozen_string_literal: true

namespace :jira do
  desc 'Extrai bugs do Jira para o JQL informado. Uso: rake jira:extract["project = XYZ AND issuetype = Bug",500]'
  task :extract, [:jql, :max_results] => :environment do |_t, args|
    jql = args[:jql] || ENV['JIRA_JQL']
    abort 'Informe JQL como primeiro argumento ou defina ENV JIRA_JQL' if jql.nil? || jql.strip.empty?
    max_results = (args[:max_results] || ENV.fetch('JIRA_MAX_RESULTS', '500')).to_i

    Rails.logger.info "[Jira] Iniciando extração. JQL='#{jql}' max_results=#{max_results}"
    client = JiraClient.new
    extractor = JiraBugsExtractor.new(client: client, jql: jql, max_results: max_results)
    extractor.call
    Rails.logger.info '[Jira] Extração concluída.'
  rescue StandardError => e
    Rails.logger.error "[Jira] Falha na extração: #{e.message}"
    raise
  end

  desc 'Auto-categorize JIRA bugs: adds mfe:, feature: and project: labels based on existing categories'
  task categorize: :environment do
    client = JiraClient.new
    bugs = JiraBug.where.not(categories: nil).where(status: "10 Done").where(team: "Digital Farm")
    total = bugs.count
    updated = 0
    skipped = 0
    errors = 0

    puts "Processing #{total} bugs..."

    bugs.find_each do |bug|
      categories = Array(bug.categories)

      puts "[#{bug.issue_key}] Processing... Current categories: #{categories.inspect}"

      result = CategoriesNormalizer.new(categories).call

      unless result[:changed?]
        puts "[#{bug.issue_key}] No changes needed, skipping"
        skipped += 1
        next
      end

      merged_labels = result[:normalized]
      puts "[#{bug.issue_key}] Labels to remove: #{result[:removed].inspect}"
      puts "[#{bug.issue_key}] Labels to add: #{result[:added].inspect}"
      puts "[#{bug.issue_key}] Final labels: #{merged_labels.inspect}"

      begin
        # Update on JIRA first
        puts "[#{bug.issue_key}] Fetching issue from JIRA..."
        jira_issue = client.fetch_issue(bug.issue_key)
        if jira_issue.nil?
          puts "[#{bug.issue_key}] SKIP - Could not fetch from JIRA"
          skipped += 1
          next
        end

        puts "[#{bug.issue_key}] Updating labels on JIRA..."
        jira_issue.save({ 'fields' => { 'labels' => merged_labels } })
        puts "[#{bug.issue_key}] JIRA labels updated successfully"

        # Persist in DB
        puts "[#{bug.issue_key}] Updating categories in DB..."
        bug.update!(categories: merged_labels)
        puts "[#{bug.issue_key}] DB categories updated successfully"
        updated += 1
      rescue StandardError => e
        puts "[#{bug.issue_key}] ERROR: #{e.message}"
        Rails.logger.error "[Jira:categorize] #{bug.issue_key}: #{e.message}"
        errors += 1
      end
    end

    puts "\nDone. Updated: #{updated}, Skipped: #{skipped}, Errors: #{errors}, Total: #{total}"
  end
end

