# frozen_string_literal: true

require "set"
require_relative "collision"
require_relative "rtree"

module CWP
  class CollisionDetector
    def initialize(versions)
      @versions = versions
      @collisions = Set.new
      @rtree = CWP::RTree.new(items: versions) { |v| bbox_for(v) }
    end

    def collisions
      result = []
      @versions.each do |v1|
        candidates = spatial_candidates(v1)
        candidates.each do |entry|
          v2 = entry[:item]
          next if v1.field_id == v2.field_id || v1.version_id == v2.version_id
          collision_id = [ v1.version_id, v2.version_id ].sort.join("-")
          next if @collisions.include?(collision_id)

          next unless v1.temporal_overlap?(v2)
          next unless v1.geometry_overlap?(v2)

          result << CWP::Collision.new(v1:, v2:)
          @collisions.add(collision_id)
        end
      end
      result
    end

    private

    def bbox_for(v)
      geom = v.geometry
      return nil unless geom
      env = geom.envelope
      if env.respond_to?(:exterior_ring)
        pts = env.exterior_ring.points
        xs = pts.map(&:x)
        ys = pts.map(&:y)
        [ xs.min, ys.min, xs.max, ys.max ]
      else
        [ env.x, env.y, env.x, env.y ]
      end
    rescue StandardError
      nil
    end

    def spatial_candidates(version)
      bbox = bbox_for(version)
      return [] unless bbox
      @rtree.search(bbox)
    end
  end
end
