# app/services/geometry_renderer.rb

require "json"
require "rgeo/geo_json"
require "chunky_png"
require "fileutils"

module CWP
  # rubocop:disable Metrics/ClassLength Metrics/MethodCount
  class GeometryRenderer
    TRANSPARENT = ChunkyPNG::Color::TRANSPARENT
    BLACK = ChunkyPNG::Color("black")
    RED = ChunkyPNG::Color("red", 180)

    def self.render_to_file(geometries, filepath, **opts)
      new(geometries, **opts).save(filepath)
    end

    def initialize(geometries, width: 300, height: 300, padding: 10, fill_color: RED, stroke_color: BLACK, palette_fill: nil, palette_stroke: nil)
      @geometries = Array(geometries).compact
      @width = width
      @height = height
      @padding = padding
      @fill_color = fill_color
      @stroke_color = stroke_color
      @palette_fill = build_palette(palette_fill) { default_fill_palette }
      @palette_stroke = build_palette(palette_stroke) { default_stroke_palette }
    end

    def render!
      return @png if @png
      @png = render_chunky
    end

    def save(filepath)
      render!
      dir = File.dirname(filepath)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
      @png.save(filepath)
      filepath
    end

    private

    def render_chunky
      img = ChunkyPNG::Image.new(@width, @height, TRANSPARENT)
      bbox = global_bbox
      return img if bbox.nil?
      scale_x, scale_y, off_x, off_y = compute_transform(bbox)
      @geometries.each_with_index do |geom, idx|
        draw_geometry(img, geom, scale_x, scale_y, off_x, off_y, idx)
      end
      img
    end

    def global_bbox
      boxes = @geometries.map { |g| geometry_bbox(resolve_geometry(g)) }.compact
      return nil if boxes.empty?
      minx = boxes.map { |b| b[0] }.min
      miny = boxes.map { |b| b[1] }.min
      maxx = boxes.map { |b| b[2] }.max
      maxy = boxes.map { |b| b[3] }.max
      [minx, miny, maxx, maxy]
    end

    def compute_transform(bbox)
      minx, miny, maxx, maxy = bbox
      span_x = (maxx - minx).abs
      span_y = (maxy - miny).abs
      span_x = 1e-9 if span_x.zero?
      span_y = 1e-9 if span_y.zero?
      drawable_w = @width - 2 * @padding
      drawable_h = @height - 2 * @padding
      scale_x = drawable_w / span_x
      scale_y = drawable_h / span_y
      scale = [scale_x, scale_y].min
      off_x = @padding
      off_y = @padding
      [scale, -scale, off_x - minx * scale, off_y + maxy * scale]
    end

    def draw_geometry(img, geom_input_raw, sx, sy, ox, oy, idx)
      geom_input, style = extract_geom_and_style(geom_input_raw)
      geom = resolve_geometry(geom_input)
      return unless geom
      fill_c = style_color(style[:fill_color], @palette_fill[idx % @palette_fill.size])
      stroke_c = style_color(style[:stroke_color], @palette_stroke[idx % @palette_stroke.size])
      case geom.geometry_type.to_s
      when /Point/i
        draw_point(img, geom, sx, sy, ox, oy, stroke_c)
      when /LineString/i
        draw_line_string(img, geom, sx, sy, ox, oy, stroke_c)
      when /Polygon/i
        draw_polygon(img, geom, sx, sy, ox, oy, fill_c, stroke_c)
      when /MultiPolygon/i
        geom.each { |pg| draw_polygon(img, pg, sx, sy, ox, oy, fill_c, stroke_c) }
      when /MultiLineString/i
        geom.each { |ls| draw_line_string(img, ls, sx, sy, ox, oy, stroke_c) }
      when /MultiPoint/i
        geom.each { |pt| draw_point(img, pt, sx, sy, ox, oy, stroke_c) }
      else
        Rails.logger.debug("GeometryRenderer: tipo não suportado #{geom.geometry_type}") if defined?(Rails)
      end
    end

    def draw_point(img, pt, sx, sy, ox, oy, stroke_c)
      x, y = project(pt.x, pt.y, sx, sy, ox, oy)
      radius = 3
      ((x - radius).to_i..(x + radius).to_i).each do |px|
        ((y - radius).to_i..(y + radius).to_i).each do |py|
          next if px < 0 || py < 0 || px >= @width || py >= @height
          img[px, py] = stroke_c
        end
      end
    end

    def draw_line_string(img, ls, sx, sy, ox, oy, stroke_c)
      pts = ls.points.map { |p| project(p.x, p.y, sx, sy, ox, oy) }
      pts.each_cons(2) { |a, b| draw_segment(img, a, b, stroke_c) }
    end

    def draw_polygon(img, poly, sx, sy, ox, oy, fill_c, stroke_c)
      exterior = normalize_ring(poly.exterior_ring.points.map { |p| project(p.x, p.y, sx, sy, ox, oy) })
      fill_polygon(img, exterior, fill_c)
      stroke_ring(img, exterior, stroke_c)
      poly.interior_rings.each do |ring|
        hole_pts = normalize_ring(ring.points.map { |p| project(p.x, p.y, sx, sy, ox, oy) })
        fill_polygon(img, hole_pts, TRANSPARENT, carve: true)
        stroke_ring(img, hole_pts, stroke_c)
      end
    rescue StandardError => e
      Rails.logger.debug("GeometryRenderer: falha ao desenhar polígono #{e.message}") if defined?(Rails)
    end

    def stroke_ring(img, pts, stroke_c)
      pts.each_cons(2) { |a, b| draw_segment(img, a, b, stroke_c) }
    end

    def draw_segment(img, a, b, color)
      x0, y0 = a
      x1, y1 = b
      dx = (x1 - x0).abs
      dy = (y1 - y0).abs
      sx = x0 < x1 ? 1 : -1
      sy = y0 < y1 ? 1 : -1
      err = dx - dy
      loop do
        set_pixel(img, x0, y0, color)
        break if (x0 - x1).abs < 1 && (y0 - y1).abs < 1
        e2 = 2 * err
        if e2 > -dy
          err -= dy
          x0 += sx
        end
        if e2 < dx
          err += dx
          y0 += sy
        end
      end
    end

    def normalize_ring(pts)
      return pts if pts.empty?
      first = pts.first
      last = pts.last
      if (first[0] - last[0]).abs > 1e-9 || (first[1] - last[1]).abs > 1e-9
        pts + [first]
      else
        pts
      end
    end

    def fill_polygon(img, pts, color, carve: false)
      return if pts.size < 4 # need at least 3 plus closing point
      ys = pts.map { |p| p[1] }
      min_y = ys.min.to_i
      max_y = ys.max.to_i
      # Build edges as pairs of points
      edges = pts.each_cons(2).to_a
      (min_y..max_y).each do |scan_y|
        intersections = []
        edges.each do |(p0, p1)|
          x0, y0 = p0
          x1, y1 = p1
          # Skip horizontal edges
          next if (y0 - y1).abs < 1e-12
          # Check if scanline intersects edge using half-open rule [min, max)
            y_min = [y0, y1].min
            y_max = [y0, y1].max
          next unless scan_y >= y_min && scan_y < y_max
          t = (scan_y - y0) / (y1 - y0).to_f
          x_int = x0 + t * (x1 - x0)
          intersections << x_int
        end
        intersections.sort.each_slice(2) do |x_start, x_end|
          next if x_end.nil?
          x0 = x_start.to_i
          x1 = x_end.to_i
          (x0..x1).each do |x|
            next if x < 0 || scan_y < 0 || x >= @width || scan_y >= @height
            if carve
              img[x, scan_y] = TRANSPARENT
            else
              # Only fill transparent pixels or carving overrides
              img[x, scan_y] = color if img[x, scan_y] == TRANSPARENT
            end
          end
        end
      end
    rescue StandardError => e
      Rails.logger.debug("GeometryRenderer: falha ao preencher polígono #{e.message}") if defined?(Rails)
    end

    def set_pixel(img, x, y, color)
      return if x < 0 || y < 0 || x >= @width || y >= @height
      img[x, y] = color
    end

    def project(x, y, sx, sy, ox, oy)
      [x * sx + ox, y * sy + oy]
    end

    def resolve_geometry(input)
      return input if input.respond_to?(:geometry_type)
      if input.is_a?(String)
        obj = JSON.parse(input) rescue nil
        return rgeo_decode(obj) if obj
      elsif input.is_a?(Hash)
        return rgeo_decode(input)
      end
      nil
    end

    def rgeo_decode(obj)
      RGeo::GeoJSON.decode(obj, json_parser: :json)
    rescue StandardError
      nil
    end

    def geometry_bbox(g)
      return nil unless g
      env = g.envelope
      if env.respond_to?(:exterior_ring)
        pts = env.exterior_ring.points
        xs = pts.map(&:x)
        ys = pts.map(&:y)
        [xs.min, ys.min, xs.max, ys.max]
      else
        [g.x, g.y, g.x, g.y]
      end
    rescue StandardError
      nil
    end

    def extract_geom_and_style(input)
      if input.is_a?(Array) && input.size == 2 && input.last.is_a?(Hash)
        [input.first, symbolize_style_keys(input.last)]
      elsif input.is_a?(Hash) && (input.key?(:geometry) || input.key?('geometry'))
        geom = input[:geometry] || input['geometry']
        style_keys = input.reject { |k, _| k.to_s == 'geometry' }
        [geom, symbolize_style_keys(style_keys)]
      else
        [input, {}]
      end
    end

    def symbolize_style_keys(h)
      h.transform_keys { |k| k.to_sym rescue k }
    end

    def style_color(raw, fallback)
      return fallback if raw.nil?
      if raw.is_a?(Integer)
        raw
      elsif raw.is_a?(String)
        hex_to_color(raw)
      else
        fallback
      end
    end

    def build_palette(passed)
      return passed.map { |c| style_color(c, RED) } if passed&.any?
      yield
    end

    def default_fill_palette
      %w[#FB5D5A #1F77B4 #2CA02C #FF7F0E #9467BD #8C564B #17BECF #E377C2].map { |hex| hex_to_color(hex) }
    end

    def default_stroke_palette
      %w[#000000 #0D3B66 #004E64 #4F372D #3A3A3A #1C1C1C #222222 #111111].map { |hex| hex_to_color(hex, 255) }
    end

    def hex_to_color(hex, alpha = 180)
      hex = hex.strip
      hex = hex[1..] if hex.start_with?('#')
      return RED if hex.length < 6
      r = hex[0..1].to_i(16)
      g = hex[2..3].to_i(16)
      b = hex[4..5].to_i(16)
      ChunkyPNG::Color.rgba(r, g, b, alpha)
    rescue StandardError
      RED
    end
  end
  # rubocop:enable Metrics/ClassLength Metrics/MethodCount
end
