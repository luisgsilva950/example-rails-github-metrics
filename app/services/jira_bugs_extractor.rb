class JiraBugsExtractor
  def initialize(client:, jql:, max_results: 500)
    @client = client
    @jql = jql
    @max_results = max_results
  end

  def call
    puts "Starting Jira bug extraction..."
    puts "JQL in use: #{@jql}"
    issues = @client.search_issues(@jql, max_results: @max_results)
    puts "Total issues returned: #{issues.size}"

    save_issues(issues)
  end

  def save_issues(issues)
    issues.each { |issue| save_issue(issue) }
  end

  private

  RCA_FIELD = "customfield_10249"
  PRIORITY_FIELD = "priority"
  TEAM_FIELD_PRIMARY = "customfield_10265"
  TEAM_FIELD_FALLBACK = "customfield_10300"
  COMMENT_FIELD = "comment"
  DESCRIPTION_FIELD = "description"
  TYPE_FIELD = "issuetype"
  REPORTER_FIELD = "reporter"
  STATUS_FIELD = "status"
  RESPONSIBLE_FIELD = "assignee"
  TITLE_FIELD = "summary"
  CREATED_FIELD = "created"
  UPDATED_FIELD = "updated"
  LABELS_FIELD = "labels"
  COMPONENT_FIELD = "components"
  DEVELOPMENT_FIELD = "customfield_10735"

  def save_issue(issue)
    fields = issue.fields
    issue_key = issue.key
    title = fields[TITLE_FIELD]
    opened_at = to_time(fields[CREATED_FIELD])
    jira_updated_at = to_time(fields[UPDATED_FIELD])
    components = Array(fields[COMPONENT_FIELD]).map { |c| c["name"] }.compact
    labels = Array(fields[LABELS_FIELD]).compact
    priority = extract_name(fields[PRIORITY_FIELD])
    issue_type = extract_name(fields[TYPE_FIELD])
    reporter = extract_name(fields[REPORTER_FIELD])
    status = extract_name(fields[STATUS_FIELD])
    assignee = extract_name(fields[RESPONSIBLE_FIELD])
    description = fields[DESCRIPTION_FIELD]
    team = extract_team(fields)
    rca = extract_rca(fields)
    development_info = fields[DEVELOPMENT_FIELD]
    development_type = extract_development_type(development_info)
    comments_struct = fields[COMMENT_FIELD]
    comments = extract_comments(comments_struct)

    new_categories = extract_categories(fields)
    normalized = CategoriesNormalizer.new(new_categories).call
    normalized_categories = normalized[:normalized]

    # If normalization changed the categories, update labels on JIRA
    if normalized[:changed?]
      Rails.logger.info("[#{issue_key}] Categories normalized: added=#{normalized[:added].inspect}, removed=#{normalized[:removed].inspect}")
      begin
        jira_issue = @client.fetch_issue(issue_key)
        if jira_issue
          jira_issue.save({ "fields" => { "labels" => normalized_categories } })
          Rails.logger.info("[#{issue_key}] JIRA labels updated after normalization")
        else
          Rails.logger.warn("[#{issue_key}] Could not fetch issue from JIRA to update labels")
        end
      rescue StandardError => e
        Rails.logger.error("[#{issue_key}] Failed to update JIRA labels: #{e.message}")
      end
    end

    JiraBug.find_or_initialize_by(issue_key: issue_key).tap do |bug|
      if bug.persisted? && bug.categories.to_set != normalized_categories.to_set
        Rails.logger.info(
          "Categories changed for #{issue_key}: #{bug.categories.inspect} -> #{normalized_categories.inspect}"
        )
      end

      bug.title = title
      bug.opened_at = opened_at
      bug.components = components
      bug.categories = normalized_categories
      bug.root_cause_analysis = rca
      bug.priority = priority
      bug.team = team
      bug.issue_type = issue_type
      bug.reporter = reporter
      bug.status = status
      bug.assignee = assignee
      bug.description = description
      bug.jira_updated_at = jira_updated_at
      bug.labels = labels
      bug.development_info = development_info
      bug.development_type = development_type
      bug.comments_count = comments&.size
      bug.comments = comments
      bug.save!
    end
  rescue StandardError => e
    Rails.logger.error "Falha ao salvar issue #{issue.key}: #{e.message}"
  end

  def to_time(value)
    return value if value.is_a?(Time)
    Time.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def extract_categories(fields)
    categories_field = fields["customfield_categories"] || fields["labels"]
    Array(categories_field).map { |v| v.is_a?(Hash) ? v["value"] : v }.compact
  end

  def extract_team(fields)
    primary = fields[TEAM_FIELD_PRIMARY]
    fallback = fields[TEAM_FIELD_FALLBACK]
    val = primary.presence || fallback
    if val.is_a?(Hash)
      val["value"] || val["name"]
    elsif val.is_a?(Array)
      val.map { |v| v.is_a?(Hash) ? (v["value"] || v["name"]) : v }.compact.join(",")
    else
      val.to_s.presence
    end
  end

  def extract_name(field_value)
    return nil if field_value.nil?
    if field_value.is_a?(Hash)
      field_value["name"] || field_value["value"] || field_value["displayName"] || field_value["emailAddress"]
    else
      field_value.to_s
    end
  end

  def extract_comments(comment_field)
    return [] if comment_field.nil?
    list = comment_field["comments"] || [] rescue []
    list.map do |c|
      {
        author: extract_name(c["author"]),
        body: c["body"],
        created: to_time(c["created"]),
        updated: to_time(c["updated"])
      }
    end
  end

  VALID_DEVELOPMENT_TYPES = %w[Backend Frontend].freeze

  def extract_development_type(dev_info)
    return nil if dev_info.nil?

    raw = if dev_info.is_a?(Hash)
            dev_info["value"] || dev_info["name"]
    elsif dev_info.is_a?(String)
            dev_info
    end

    raw if VALID_DEVELOPMENT_TYPES.include?(raw)
  end

  def extract_rca(fields)
    rca_field = fields[RCA_FIELD]
    return rca_field if rca_field.is_a?(String)
    if rca_field.is_a?(Hash)
      rca_field["value"] || rca_field["name"] || rca_field["text"]
    else
      fields["customfield_root_cause_analysis"] || fields["Root Cause"] || fields["RCA"]
    end
  end
end
