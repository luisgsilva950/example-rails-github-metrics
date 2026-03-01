namespace :slack do
  desc "Fetch messages from a Slack channel and print basic info"
  task :fetch_channel_messages, [ :channel_id, :max_pages ] => :environment do |_, args|
    channel_id = args[:channel_id] || ENV["SLACK_CHANNEL_ID"]
    max_pages  = args[:max_pages]&.to_i if args[:max_pages]

    unless channel_id.present?
      puts "You must provide a channel_id argument or set SLACK_CHANNEL_ID env var."
      exit 1
    end

    client = SlackClient.new

    puts "Fetching messages from Slack channel: #{channel_id}"
    messages = client.enumerate_channel_messages(channel_id, max_pages: max_pages)

    puts "Fetched #{messages.size} messages from channel #{channel_id}"
  end
end
