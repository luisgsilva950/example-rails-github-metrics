# frozen_string_literal: true

require "fileutils"
require "json"
require_relative "geometry_renderer"

module CWP
  class Collision
    def initialize(v1:, v2:)
      puts "Collision detected between Field #{v1.field_id} (period #{v1.starts_at}:#{v1.ends_at}) and Field #{v2.field_id} (period #{v2.starts_at}:#{v2.ends_at}), Created ats #{v1.created_at} & #{v2.created_at}"
      @v1 = v1
      @v2 = v2

      Dir.mkdir("#{__dir__}/collisions/#{v1.property_id}") rescue nil

      path = "#{__dir__}/collisions/#{v1.property_id}/#{v1.field_id}_#{v1.period}_#{v2.field_id}_#{v2.period}.json"
      puts "Saving collision geometry image to #{path}"

      feature1 = RGeo::GeoJSON::Feature.new(v1.geometry, v1.field_id, { name: v1.name, valid_since: v1.starts_at, valid_until: v1.ends_at, created_at: v1.created_at, fill: "#b5q002" })
      feature2 = RGeo::GeoJSON::Feature.new(v2.geometry, v2.field_id, { name: v2.name, valid_since: v2.starts_at, valid_until: v2.ends_at, created_at: v2.created_at, fill: "#f50002" })
      geojson = RGeo::GeoJSON::FeatureCollection.new([ feature1, feature2 ])

      return unless geojson
      geojson = RGeo::GeoJSON.encode(geojson)
      geojson = JSON.pretty_generate(geojson)
      File.write(path, geojson)
    end
  end
end
