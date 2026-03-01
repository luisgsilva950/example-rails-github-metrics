#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require_relative '../lib/cwp/client'
require_relative '../lib/cwp/collision_detector'

options = {
  url: nil,
  token: ENV['CWP_TOKEN'],
  property_id: nil
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby script/cwp_field_collisions.rb --url BASE_URL --property PROPERTY_ID [--token CWP_TOKEN]"
  opts.on('--url URL', 'Base URL da API (ex: https://api.cropwise.com)') { |v| options[:url] = v }
  opts.on('--property PROPERTY_ID', 'ID da propriedade') { |v| options[:property_id] = v }
  opts.on('--token TOKEN', 'CWP OAuth token (Bearer)') { |v| options[:token] = v }
end

parser.parse!

abort('Missing --url') unless options[:url]
abort('Missing --property') unless options[:property_id]
abort('Missing token (env CWP_TOKEN or --token)') unless options[:token]

client = CWP::Client.new(base_url: options[:url], token: options[:token])
versions = client.fetch_field_history(options[:property_id])

if versions.empty?
  puts 'No field versions found.'
  exit 0
end

detector = CWP::CollisionDetector.new(versions)
collisions = detector.collisions

if collisions.empty?
  puts 'No collisions detected.'
  exit 0
end

# Print table header
headers = %w[field_id_a version_id_a field_id_b version_id_b temporal geometric]
widths = headers.map { |h| [h.length, 16].max }

puts headers.map.with_index { |h, i| h.ljust(widths[i]) }.join(' | ')
puts widths.map { |w| '-' * w }.join('-+-')

collisions.each do |c|
  row = [c.field_id_a, c.version_id_a, c.field_id_b, c.version_id_b, c.temporal, c.geometric]
  puts row.map.with_index { |v, i| v.to_s.ljust(widths[i]) }.join(' | ')
end
