# frozen_string_literal: true
# Minimal bulk-load R-Tree (STR variant) for static datasets.
# Supports building from an array of items with bounding boxes and querying overlapping boxes.
# Item must respond to :geometry and :version_id (for collision filtering) or supply bbox explicitly.

module CWP
  class RTree
    MAX_ENTRIES = 16

    Node = Struct.new(:children, :bbox, :leaf)

    def initialize(items: [], &bbox_block)
      @bbox_block = bbox_block || proc { |item| compute_bbox(item) }
      build(items)
    end

    def search(query_bbox)
      return [] if @root.nil? || query_bbox.nil?
      results = []
      stack = [ @root ]
      while (node = stack.pop)
        next unless overlaps?(node.bbox, query_bbox)
        if node.leaf
          node.children.each do |entry|
            results << entry if overlaps?(entry[:bbox], query_bbox)
          end
        else
          node.children.each { |child| stack << child if overlaps?(child.bbox, query_bbox) }
        end
      end
      results
    end

    private

    def build(items)
      entries = items.map do |it|
        bbox = @bbox_block.call(it)
        next if bbox.nil?
        { item: it, bbox: bbox }
      end.compact
      @root = bulk_load(entries)
    end

    def bulk_load(entries)
      return nil if entries.empty?
      # STR bulk-load: sort by minx, slice into groups, then sort each group by miny.
      slice_size = Math.sqrt(entries.size).ceil
      sorted_x = entries.sort_by { |e| e[:bbox][0] }
      slices = sorted_x.each_slice(slice_size).to_a
      leaf_nodes = slices.flat_map do |slice|
        slice.sort_by { |e| e[:bbox][1] }.each_slice(MAX_ENTRIES).map do |group|
          make_leaf(group)
        end
      end
      build_level(leaf_nodes)
    end

    def build_level(nodes)
      return nodes.first if nodes.size == 1
      slice_size = Math.sqrt(nodes.size).ceil
      sorted = nodes.sort_by { |n| n.bbox[0] }
      slices = sorted.each_slice(slice_size).to_a
      parents = slices.flat_map do |slice|
        slice.sort_by { |n| n.bbox[1] }.each_slice(MAX_ENTRIES).map do |group|
          make_parent(group)
        end
      end
      build_level(parents)
    end

    def make_leaf(group)
      Node.new(group, union_bbox(group.map { |e| e[:bbox] }), true)
    end

    def make_parent(children)
      bbox = union_bbox(children.map(&:bbox))
      Node.new(children, bbox, false)
    end

    def compute_bbox(item)
      geom = item.respond_to?(:geometry) ? item.geometry : nil
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

    def union_bbox(bboxes)
      minx = bboxes.map { |b| b[0] }.min
      miny = bboxes.map { |b| b[1] }.min
      maxx = bboxes.map { |b| b[2] }.max
      maxy = bboxes.map { |b| b[3] }.max
      [ minx, miny, maxx, maxy ]
    end

    def overlaps?(a, b)
      !(a[2] < b[0] || b[2] < a[0] || a[3] < b[1] || b[3] < a[1])
    end
  end
end

