# frozen_string_literal: true

module JiraBugs
  # Converts a time into a bucket key (daily, weekly, or monthly).
  # Returns a string key and provides label formatting.
  class FormatTimeBucket
    STRATEGIES = {
      "daily" => ->(t) { t.strftime("%Y-%m-%d") },
      "weekly" => ->(t) { t.beginning_of_week(:monday).strftime("%Y-%m-%d") },
      "monthly" => ->(t) { t.strftime("%Y-%m") }
    }.freeze

    def initialize(group_by: "weekly")
      @group_by = group_by
      @strategy = STRATEGIES.fetch(group_by, STRATEGIES["weekly"])
    end

    def bucket(time)
      @strategy.call(time)
    end

    def format_label(key)
      case @group_by
      when "daily"   then Date.parse(key).strftime("%d/%m/%Y")
      when "monthly" then Date.parse("#{key}-01").strftime("%b %Y")
      else weekly_label(key)
      end
    end

    private

    def weekly_label(key)
      d = Date.parse(key)
      "#{d.strftime('%d/%m')} – #{(d + 6).strftime('%d/%m')}"
    end
  end
end
