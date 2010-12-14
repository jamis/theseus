require 'chunky_png'

module Theseus
  module Formatters
    class PNG
      DEFAULTS = {
        :cell_size      => 10,
        :wall_width     => 1,
        :wall_color     => 0x000000FF,
        :cell_color     => 0xFFFFFFFF,
        :solution_color => 0xFFAFAFFF,
        :background     => 0x00000000,
        :outer_padding  => 2,
        :cell_padding   => 1,
        :solution       => false
      }

      ANY_N = Maze::N | (Maze::N << Maze::UNDER_SHIFT)
      ANY_S = Maze::S | (Maze::S << Maze::UNDER_SHIFT)
      ANY_W = Maze::W | (Maze::W << Maze::UNDER_SHIFT)
      ANY_E = Maze::E | (Maze::E << Maze::UNDER_SHIFT)

      attr_reader :options

      def initialize(maze, options)
        @options = DEFAULTS.merge(options)

        [:background, :wall_color, :cell_color, :solution_color].each do |c|
          @options[c] = ChunkyPNG::Color.from_hex(@options[c]) unless Fixnum === @options[c]
        end
      end

      def to_blob
        @blob
      end

      # returns the projection of point p onto the line that passes through a and c
      def project(p, a, c)
        # equation of line ac, y = m1 * x + b1
        m1 = (c[1] - a[1]) / (c[0] - a[0]).to_f
        b1 = a[1] - m1 * a[0]

        # equation of line through p that is perpendicular to ac
        # y = m2 * x + b2
        m2 = -1 / m1
        b2 = p[1] - m2 * p[0]

        # solve for intersection of two lines
        dx = (m1 * a[0] - a[1] - m2 * p[0] + p[1]) / (m1 - m2)
        dy = m1 * dx + b1

        return [dx, dy]
      end

      def move(point, dx, dy)
        [point[0] + dx, point[1] + dy]
      end

      def clamp(x, low, hi)
        x = low if x < low
        x = hi  if x > hi
        return x
      end

      def line(canvas, p1, p2, color)
        canvas.line(
          clamp(p1[0].round, 0, canvas.width-1),
          clamp(p1[1].round, 0, canvas.height-1),
          clamp(p2[0].round, 0, canvas.width-1),
          clamp(p2[1].round, 0, canvas.height-1),
          color)
      end

      def fill_rect(canvas, x0, y0, x1, y1, color)
        x0 = clamp(x0, 0, canvas.width-1)
        y0 = clamp(y0, 0, canvas.height-1)
        x1 = clamp(x1, 0, canvas.width-1)
        y1 = clamp(y1, 0, canvas.height-1)
        [x0, x1].min.ceil.upto([x0, x1].max.floor) do |x|
          [y0, y1].min.ceil.upto([y0, y1].max.floor) do |y|
            canvas.point(x, y, color)
          end
        end
      end

      def fill_poly(canvas, points, color)
        min_y = 1_000_000
        max_y = -1_000_000
        points.each do |x,y|
          min_y = y if y < min_y
          max_y = y if y > max_y
        end

        min_y = clamp(min_y, 0, canvas.height-1)
        max_y = clamp(max_y, 0, canvas.height-1)

        min_y.floor.upto(max_y.ceil) do |y|
          nodes = []

          prev = points.last
          points.each do |point|
            if point[1] < y && prev[1] >= y || prev[1] < y && point[1] >= y
              nodes << (point[0] + (y - point[1]).to_f / (prev[1] - point[1]) * (prev[0] - point[0]))
            end
            prev = point
          end

          next if nodes.empty?
          nodes.sort!

          prev = nil
          0.step(nodes.length-1, 2) do |a|
            x1, x2 = nodes[a], nodes[a+1]
            x1, x2 = x2, x1 if x1 > x2
            next if x1 < 0 || x2 >= canvas.width
            x1.ceil.upto(x2.floor) do |x|
              canvas.point(x, y, color)
            end
          end
        end
      end
    end
  end
end
