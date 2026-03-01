# frozen_string_literal: true

require "net/http"
require "json"
require "uri"
require "rgeo"
require "rgeo/geos"
require "rgeo/geo_json"
require "rgeo/feature"
require "date"
require "openssl"
require_relative "field_version"

module CWP
  class Client
    def initialize(base_url:, token:, open_timeout: 30, read_timeout: 300)
      @base_url = base_url.chomp("/")
      @token = token
      @open_timeout = open_timeout
      @read_timeout = read_timeout
      @factory = RGeo::Geos.factory(srid: 4326, has_z_coordinate: true, has_m_coordinate: true)
    end

    def fetch_field_history(property_id)
      path = "/v2/properties/#{property_id}/fields/history?attributes=geometry"
      uri = URI.join(@base_url + "/", path)
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"] = "application/json"

      host = uri.host
      port = uri.port
      raise "URI host inválido" if host.nil?
      raise "URI port inválido" if port.nil?

      http = Net::HTTP.new(host, port)

      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      http.open_timeout = @open_timeout
      http.read_timeout = @read_timeout

      res = http.start { |h| h.request(req) }

      unless res.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch field history: #{res.code} #{res.body}"
      end

      body = JSON.parse(res.body)
      fields_arr = body.is_a?(Hash) ? body["fields"] : body
      return [] unless fields_arr.is_a?(Array)
      fields_arr.flat_map { |field_entry| parse_field_entry(field_entry) }.compact
    end

    private

    def parse_field_entry(field_entry)
      field_id = field_entry["id"]
      versions = field_entry["versions"]
      return [] unless field_id && versions.is_a?(Array)
      versions.map { |v| parse_field_version(field_id, v) }.compact
    end

    def parse_field_version(field_id, v)
      version_id = v["version_id"] || v["id"]
      starts_at = parse_dt(v["valid_since"])
      ends_at = parse_dt(v["valid_until"])
      geometry = decode_geometry(v["geometry"])
      return nil unless geometry
      CWP::FieldVersion.new(property_id: v["property_id"],
                            field_id: field_id,
                            name: v["name"],
                            version_id: version_id,
                            geometry: geometry,
                            created_at: v["created_at"],
                            starts_at: starts_at,
                            ends_at: ends_at)
    end

    def parse_dt(str)
      return nil if str.nil? || str.empty?
      DateTime.parse(str).to_date
    rescue StandardError
      nil
    end

    def decode_geometry(geojson)
      return nil if geojson.nil?
      if geojson.is_a?(String)
        geojson = JSON.parse(geojson) rescue nil
        return nil if geojson.nil?
      end
      RGeo::GeoJSON.decode(geojson, json_parser: :json, geo_factory: @factory)
    rescue StandardError => e
      nil
    end
  end
end
