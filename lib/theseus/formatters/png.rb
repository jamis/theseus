require 'chunky_png'

module Theseus
  module Formatters
    # This is an abstract superclass for PNG formatters. It simply provides some common
    # utility and drawing methods that subclasses can take advantage of, to render
    # mazes to a PNG canvas.
    #
    # Colors are given as 32-bit integers, with each RGBA component occupying 1 byte.
    # R is the highest byte, A is the lowest byte. In other words, 0xFF0000FF is an
    # opaque red, and 0x7f7f7f7f is a semi-transparent gray. 0x0 is fully transparent.
    #
    # You may also provide the colors as hexadecimal string values, and they will be
    # converted to the corresponding integers.
    class PNG
      # The default options. Note that not all PNG formatters honor all of these options;
      # specifically, +:wall_width+ is not consistently supported across all formatters.
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

      # North, whether in the under or primary plane
      ANY_N = Maze::N | (Maze::N << Maze::UNDER_SHIFT)

      # South, whether in the under or primary plane
      ANY_S = Maze::S | (Maze::S << Maze::UNDER_SHIFT)

      # West, whether in the under or primary plane
      ANY_W = Maze::W | (Maze::W << Maze::UNDER_SHIFT)

      # East, whether in the under or primary plane
      ANY_E = Maze::E | (Maze::E << Maze::UNDER_SHIFT)

      # The options to use for the formatter. These are the ones passed
      # to the constructor, plus the ones from the DEFAULTS hash.
      attr_reader :options

      # The +options+ must be a hash of any of the following options:
      #
      # [:cell_size]      The number of pixels on a side that each cell
      #                   should occupy. Different maze types will use that
      #                   space differently. Also, the cell padding is applied
      #                   inside the cell, and so consumes some of the area.
      #                   The default is 10.
      # [:wall_width]     How thick the walls should be drawn. The default is 1.
      #                   Note that not all PNG formatters will honor this value
      #                   (yet).
      # [:wall_color]     The color to use when drawing the wall. Defaults to black.
      # [:cell_color]     The color to use when drawing the cell. Defaults to white.
      # [:solution_color] The color to use when drawing the solution path. This is
      #                   only used when the :solution option is given.
      # [:background]     The color to use for the background of the maze. Defaults
      #                   to transparent.
      # [:outer_padding]  The extra padding (in pixels) to add around the outside
      #                   edge of the maze. Defaults to 2.
      # [:cell_padding]   The padding (in pixels) to add around the inside of each
      #                   cell. This has the effect of separating the cells. The
      #                   default cell padding is 1.
      # [:solution]       A boolean value indicating whether or not to draw the
      #                   solution path as well. The default is false.
      def initialize(maze, options)
        @options = DEFAULTS.merge(options)

        [:background, :wall_color, :cell_color, :solution_color].each do |c|
          @options[c] = ChunkyPNG::Color.from_hex(@options[c]) if String === @options[c]
        end

        @paths = @options[:paths] || []

        if @options[:solution]
          path = maze.new_solver(type: @options[:solution]).solve.to_path(color: @options[:solution_color])
          @paths = [path, *@paths]
        end
      end

      # Returns the raw PNG data for the formatter.
      def to_blob
        @blob
      end

      # Returns the color at the given point by considering all provided paths. The
      # +:color: metadata from the first path that is set at the given point is
      # returned. If no path describes the given point, then the value of the
      # +:cell_color+ option is returned.
      def color_at(pt, direction=nil)
        @paths.each do |path|
          return path[:color] if direction ? path.path?(pt, direction) : path.set?(pt)
        end

        return @options[:cell_color]
      end

      # Returns a new 2-tuple (x2,y2), where x2 is point[0] + dx, and y2 is point[1] + dy.
      def move(point, dx, dy)
        [point[0] + dx, point[1] + dy]
      end

      # Clamps the value +x+ so that it lies between +low+ and +hi+. In other words,
      # returns +low+ if +x+ is less than +low+, and +high+ if +x+ is greater than
      # +high+, and returns +x+ otherwise.
      def clamp(x, low, hi)
        x = low if x < low
        x = hi  if x > hi
        return x
      end

      # Draws a line from +p1+ to +p2+ on the given canvas object, in the given
      # color. The coordinates of the given points are clamped (naively) to lie
      # within the canvas' bounds.
      def line(canvas, p1, p2, color)
        canvas.line(
          clamp(p1[0].floor, 0, canvas.width-1),
          clamp(p1[1].floor, 0, canvas.height-1),
          clamp(p2[0].floor, 0, canvas.width-1),
          clamp(p2[1].floor, 0, canvas.height-1),
          color)
      end

      # Fills the rectangle defined by the given coordinates with the given color.
      # The coordinates are clamped to lie within the canvas' bounds.
      def fill_rect(canvas, x0, y0, x1, y1, color)
        x0 = clamp(x0, 0, canvas.width-1).floor
        y0 = clamp(y0, 0, canvas.height-1).floor
        x1 = clamp(x1, 0, canvas.width-1).floor
        y1 = clamp(y1, 0, canvas.height-1).floor
        canvas.rect(x0, y0, x1, y1, color, color)
      end

      # Fills the polygon defined by the +points+ array, with the given +color+.
      # Each element of +points+ must be a 2-tuple describing a vertex of the
      # polygon. It is assumed that the polygon is closed. All points are
      # clamped (naively) to lie within the canvas' bounds.
      def fill_poly(canvas, points, color)
        clamped = points.map do |(x, y)|
          [ clamp(x.floor, 0, canvas.width - 1),
            clamp(y.floor, 0, canvas.height - 1) ]
        end

        canvas.polygon(clamped, color, color)
      end
    end
  end
end
