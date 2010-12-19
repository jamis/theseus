require 'theseus/formatters/png'

module Theseus
  module Formatters
    class PNG
      # Renders a DeltaMaze to a PNG canvas. Does not currently support the
      # +:wall_width+ option.
      #
      # You will almost never access this class directly. Instead, use
      # DeltaMaze#to(:png, options) to return the raw PNG data directly.
      class Delta < PNG
        # Create and return a fully initialized PNG::Delta object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
          width = @options[:outer_padding] * 2 + (maze.width + 1) * @options[:cell_size] / 2

          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.row_length(y).times do |x|
              px = @options[:outer_padding] + x * @options[:cell_size] / 2.0
              draw_cell(canvas, [x, y], maze.points_up?(x,y), px, py, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_cell(canvas, point, up, x, y, cell) #:nodoc:
          return if cell == 0

          p1 = [x + options[:cell_size] / 2.0, up ? (y + options[:cell_padding]) : (y + options[:cell_size] - options[:cell_padding])]
          p2 = [x + options[:cell_padding], up ? (y + options[:cell_size] - options[:cell_padding]) : (y + options[:cell_padding])]
          p3 = [x + options[:cell_size] - options[:cell_padding], p2[1]]

          fill_poly(canvas, [p1, p2, p3], color_at(point))

          if cell & (Maze::N | Maze::S) != 0
            clr = color_at(point, (Maze::N | Maze::S))
            dy = options[:cell_padding]
            sign = (cell & Maze::N != 0) ? -1 : 1
            r1, r2 = p2, move(p3, 0, sign*dy)
            fill_rect(canvas, r1[0].round, r1[1].round, r2[0].round, r2[1].round, clr)
            line(canvas, r1, [r1[0], r2[1]], options[:wall_color])
            line(canvas, r2, [r2[0], r1[1]], options[:wall_color])
          else
            line(canvas, p2, p3, options[:wall_color])
          end

          dx = options[:cell_padding]
          if cell & ANY_W != 0
            r1, r2, r3, r4 = p1, move(p1,-dx,0), move(p2,-dx,0), p2
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, ANY_W))
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::W == 0
            line(canvas, p1, p2, options[:wall_color])
          end

          if cell & ANY_E != 0
            r1, r2, r3, r4 = p1, move(p1,dx,0), move(p3,dx,0), p3
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, ANY_E))
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::E == 0
            line(canvas, p3, p1, options[:wall_color])
          end
        end
      end
    end
  end
end

