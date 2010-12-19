require 'theseus/formatters/png'

module Theseus
  module Formatters
    class PNG
      # Renders an OrthogonalMaze to a PNG canvas.
      #
      # You will almost never access this class directly. Instead, use
      # OrthogonalMaze#to(:png, options) to return the raw PNG data directly.
      class Orthogonal < PNG
        # Create and return a fully initialized PNG::Orthogonal object, with the
        # maze rendered. To get the maze data, call #to_blob.
        #
        # See Theseus::Formatters::PNG for a list of all supported options.
        def initialize(maze, options={})
          super

          width  = @options[:outer_padding] * 2 + maze.width * @options[:cell_size]
          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
          
          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          @d1 = @options[:cell_padding]
          @d2 = @options[:cell_size] - @options[:cell_padding]
          @w1 = (@options[:wall_width] / 2.0).floor
          @w2 = ((@options[:wall_width] - 1) / 2.0).floor

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.width.times do |x|
              px = @options[:outer_padding] + x * @options[:cell_size]
              draw_cell(canvas, [x, y], px, py, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        private

        def draw_cell(canvas, point, x, y, cell) #:nodoc:
          return if cell == 0

          fill_rect(canvas, x + @d1, y + @d1, x + @d2, y + @d2, color_at(point))

          north = cell & Maze::N == Maze::N
          north_under = (cell >> Maze::UNDER_SHIFT) & Maze::N == Maze::N
          south = cell & Maze::S == Maze::S
          south_under = (cell >> Maze::UNDER_SHIFT) & Maze::S == Maze::S
          west = cell & Maze::W == Maze::W
          west_under = (cell >> Maze::UNDER_SHIFT) & Maze::W == Maze::W
          east = cell & Maze::E == Maze::E
          east_under = (cell >> Maze::UNDER_SHIFT) & Maze::E == Maze::E

          draw_vertical(canvas, x, y, 1, north || north_under, !north || north_under, color_at(point, ANY_N))
          draw_vertical(canvas, x, y + options[:cell_size], -1, south || south_under, !south || south_under, color_at(point, ANY_S))
          draw_horizontal(canvas, x, y, 1, west || west_under, !west || west_under, color_at(point, ANY_W))
          draw_horizontal(canvas, x + options[:cell_size], y, -1, east || east_under, !east || east_under, color_at(point, ANY_E))
        end

        def draw_vertical(canvas, x, y, direction, corridor, wall, color) #:nodoc:
          if corridor
            fill_rect(canvas, x + @d1, y, x + @d2, y + @d1 * direction, color)
            fill_rect(canvas, x + @d1 - @w1, y - (@w1 * direction), x + @d1 + @w2, y + (@d1 + @w2) * direction, options[:wall_color])
            fill_rect(canvas, x + @d2 - @w2, y - (@w1 * direction), x + @d2 + @w1, y + (@d1 + @w2) * direction, options[:wall_color])
          end

          if wall
            fill_rect(canvas, x + @d1 - @w1, y + (@d1 - @w1) * direction, x + @d2 + @w2, y + (@d1 + @w2) * direction, options[:wall_color])
          end
        end

        def draw_horizontal(canvas, x, y, direction, corridor, wall, color) #:nodoc:
          if corridor
            fill_rect(canvas, x, y + @d1, x + @d1 * direction, y + @d2, color)
            fill_rect(canvas, x - (@w1 * direction), y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d1 + @w2, options[:wall_color])
            fill_rect(canvas, x - (@w1 * direction), y + @d2 - @w2, x + (@d1 + @w2) * direction, y + @d2 + @w1, options[:wall_color])
          end

          if wall
            fill_rect(canvas, x + (@d1 - @w1) * direction, y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d2 + @w2, options[:wall_color])
          end
        end
      end
    end
  end
end
