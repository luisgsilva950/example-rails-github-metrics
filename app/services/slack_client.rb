class SlackClient
  def initialize(token: nil, web_client: nil)
    configure_slack

    @token = token || ENV["SLACK_BOT_TOKEN"] || fetch_token_from_credentials!
    @web = web_client || Slack::Web::Client.new(token: @token)
  end

  # Retorna o hash completo de informações de um canal
  def channel_info(channel_id)
    @web.conversations_info(channel: channel_id).channel
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Slack channel_info error: #{e.class} - #{e.message}")
    nil
  end

  def channel_messages(channel_id, limit: 200, cursor: nil, oldest: nil, latest: nil)
    params = {
      channel: channel_id,
      limit: limit
    }
    params[:cursor]  = cursor if cursor
    params[:oldest]  = oldest if oldest
    params[:latest]  = latest if latest

    resp = @web.conversations_history(params)

    messages = resp.messages || []
    next_cursor = resp.response_metadata&.next_cursor

    { messages: messages, next_cursor: (next_cursor.presence if next_cursor.respond_to?(:presence)) || (next_cursor unless next_cursor.to_s.empty?) }
  rescue Slack::Web::Api::Errors::SlackError => e
    Rails.logger.error("Slack channel_messages error: #{e.class} - #{e.message}")
    { messages: [], next_cursor: nil }
  end

  def enumerate_channel_messages(channel_id, oldest: nil, latest: nil, page_limit: 200, max_pages: nil)
    all_messages = []
    cursor = nil
    pages_fetched = 0

    loop do
      break if max_pages && pages_fetched >= max_pages

      result = channel_messages(channel_id, limit: page_limit, cursor: cursor, oldest: oldest, latest: latest)
      msgs = result[:messages]
      all_messages.concat(msgs)

      cursor = result[:next_cursor]
      pages_fetched += 1

      break if cursor.nil? || cursor.to_s.empty?
    end

    all_messages
  end

  private

  def configure_slack
    return if defined?(@@slack_configured) && @@slack_configured

    Slack.configure do |config|
      # O token é passado diretamente no client, mas podemos manter um default aqui se quiser
      config.logger = Rails.logger if defined?(Rails)
    end

    @@slack_configured = true
  end

  def fetch_token_from_credentials!
    if defined?(Rails) && Rails.application.respond_to?(:credentials)
      cred = Rails.application.credentials.dig(:slack, :bot_token)
      return cred if cred.present?
    end
    raise "Slack bot token not configured. Set SLACK_BOT_TOKEN env or credentials[:slack][:bot_token]."
  end
end
