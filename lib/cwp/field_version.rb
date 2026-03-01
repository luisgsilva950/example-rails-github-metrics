# frozen_string_literal: true

require "date"
require "rgeo"
require "rgeo/geos"

module CWP
  class FieldVersion
    MAX_DATE = DateTime.new(9999, 12, 31, 23, 59, 59)
    MIN_DATE = DateTime.new(-4712, 1, 1)

    attr_reader :property_id, :field_id, :name, :version_id, :geometry, :created_at, :starts_at, :ends_at

    def initialize(property_id:, field_id:, name:, version_id:, geometry:, created_at:, starts_at:, ends_at:)
      @property_id = property_id
      @field_id = field_id
      @name = name
      @version_id = version_id
      @geometry = geometry
      @starts_at = starts_at
      @ends_at = ends_at
      @created_at = created_at
    end

    def period
      "#{starts_at || 'NULL'}_#{ends_at || 'NULL'}"
    end

    def temporal_overlap?(other)
      starts = starts_at || MIN_DATE.to_date
      ends = ends_at || MAX_DATE.to_date
      o_starts = other.starts_at || MIN_DATE.to_date
      o_ends = other.ends_at || MAX_DATE.to_date
      return false if starts.nil? || ends.nil? || o_starts.nil? || o_ends.nil?
      (starts <= o_ends) && (o_starts <= ends)
    end

    def geometry_overlap?(other)
      return false if geometry.nil? || other.geometry.nil?
      intersection = geometry.intersection(other.geometry)
      RGeo::Feature::Polygon.check_type(intersection) && intersection.area > 0
    end
  end
end
