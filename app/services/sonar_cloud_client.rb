class SonarCloudClient
  BASE_URL = "https://sonarcloud.io/api"
  MAX_RETRIES = 3
  RETRY_DELAY = 2
  RETRYABLE_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNRESET, Errno::ECONNREFUSED ].freeze

  METRIC_KEYS = %w[
    bugs vulnerabilities code_smells security_hotspots ncloc
    coverage duplicated_lines_density
    reliability_rating security_rating sqale_rating
  ].freeze

  def initialize(token: ENV.fetch("SONAR_TOKEN", nil), organization: ENV.fetch("SONAR_ORGANIZATION", nil))
    @token = token
    @organization = organization
  end

  def projects(page: 1, page_size: 500)
    get("/components/search", organization: @organization, p: page, ps: page_size, qualifiers: "TRK")
  end

  def measures(component_key:)
    get("/measures/component", component: component_key, metricKeys: METRIC_KEYS.join(","))
  end

  def issues(component_key:, page: 1, page_size: 100, created_after: nil)
    params = { componentKeys: component_key, p: page, ps: page_size }
    params[:createdAfter] = created_after.strftime("%Y-%m-%dT%H:%M:%S%z") if created_after
    get("/issues/search", params)
  end

  private

  def get(path, params = {})
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params)

    with_retries { execute_request(uri) }
  end

  def execute_request(uri)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{@token}"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.request(request)
    end

    handle_response(response)
  end

  def with_retries
    attempts = 0

    begin
      attempts += 1
      yield
    rescue *RETRYABLE_ERRORS
      raise if attempts >= MAX_RETRIES

      sleep(RETRY_DELAY * attempts)
      retry
    end
  end

  def handle_response(response)
    return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)

    raise "SonarCloud API error (#{response.code}): #{response.body}"
  end
end
