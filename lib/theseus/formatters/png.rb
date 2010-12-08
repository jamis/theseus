# encoding: UTF-8

require 'chunky_png'
require 'theseus/solver'

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

      def initialize(maze, options={})
        @options = DEFAULTS.merge(options)

        width  = @options[:outer_padding] * 2 + maze.width * @options[:cell_size]
        height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
        
        [:background, :wall_color, :cell_color, :solution_color].each do |c|
          @options[c] = ChunkyPNG::Color.from_hex(@options[c]) unless Fixnum === @options[c]
        end

        canvas = ChunkyPNG::Image.new(width, height, @options[:background])
        def canvas.fill_rect(x0, y0, x1, y1, color)
          [x0, x1].min.upto([x0, x1].max) do |x|
            [y0, y1].min.upto([y0, y1].max) do |y|
              point(x, y, color)
            end
          end
        end

        @d1 = @options[:cell_padding]
        @d2 = @options[:cell_size] - @options[:cell_padding]
        @w1 = (@options[:wall_width] / 2.0).floor
        @w2 = ((@options[:wall_width] - 1) / 2.0).floor

        if @options[:solution]
          solution_grid = Solver.new(maze).solution_grid
        end

        maze.height.times do |y|
          py = @options[:outer_padding] + y * @options[:cell_size]
          maze.width.times do |x|
            px = @options[:outer_padding] + x * @options[:cell_size]
            draw_cell(canvas, px, py, maze[x, y], solution_grid ? solution_grid[x][y] : 0)
          end
        end

        @blob = canvas.to_blob
      end

      def to_blob
        @blob
      end

      def draw_solution_segment(canvas, x0, y0, x1, y1)
        canvas.line(x0, y0, x1, y1, @options[:solution_color])
      end

      ANY_NORTH = Maze::NORTH | (Maze::NORTH << Maze::UNDER_SHIFT)
      ANY_SOUTH = Maze::SOUTH | (Maze::SOUTH << Maze::UNDER_SHIFT)
      ANY_WEST = Maze::WEST | (Maze::WEST << Maze::UNDER_SHIFT)
      ANY_EAST = Maze::EAST | (Maze::EAST << Maze::UNDER_SHIFT)

      def draw_cell(canvas, x, y, cell, solution)
        return if cell == 0

        color = (solution & cell != 0) ? :solution_color : :cell_color

        canvas.fill_rect(x + @d1, y + @d1, x + @d2, y + @d2, @options[color])

        north = cell & Maze::NORTH == Maze::NORTH
        north_under = (cell >> Maze::UNDER_SHIFT) & Maze::NORTH == Maze::NORTH
        south = cell & Maze::SOUTH == Maze::SOUTH
        south_under = (cell >> Maze::UNDER_SHIFT) & Maze::SOUTH == Maze::SOUTH
        west = cell & Maze::WEST == Maze::WEST
        west_under = (cell >> Maze::UNDER_SHIFT) & Maze::WEST == Maze::WEST
        east = cell & Maze::EAST == Maze::EAST
        east_under = (cell >> Maze::UNDER_SHIFT) & Maze::EAST == Maze::EAST

        draw_vertical(canvas, x, y, 1, north || north_under, !north || north_under, solution & ANY_NORTH != 0 ? :solution_color : :cell_color) 
        draw_vertical(canvas, x, y + @options[:cell_size], -1, south || south_under, !south || south_under, solution & ANY_SOUTH != 0 ? :solution_color : :cell_color)
        draw_horizontal(canvas, x, y, 1, west || west_under, !west || west_under, solution & ANY_WEST != 0 ? :solution_color : :cell_color)
        draw_horizontal(canvas, x + @options[:cell_size], y, -1, east || east_under, !east || east_under, solution & ANY_EAST != 0 ? :solution_color : :cell_color)
      end

      def draw_vertical(canvas, x, y, direction, corridor, wall, color)
        if corridor
          canvas.fill_rect(x + @d1, y, x + @d2, y + @d1 * direction, @options[color])
          canvas.fill_rect(x + @d1 - @w1, y - (@w1 * direction), x + @d1 + @w2, y + (@d1 + @w2) * direction, @options[:wall_color])
          canvas.fill_rect(x + @d2 - @w2, y - (@w1 * direction), x + @d2 + @w1, y + (@d1 + @w2) * direction, @options[:wall_color])
        end

        if wall
          canvas.fill_rect(x + @d1 - @w1, y + (@d1 - @w1) * direction, x + @d2 + @w2, y + (@d1 + @w2) * direction, @options[:wall_color])
        end
      end

      def draw_horizontal(canvas, x, y, direction, corridor, wall, color)
        if corridor
          canvas.fill_rect(x, y + @d1, x + @d1 * direction, y + @d2, @options[color])
          canvas.fill_rect(x - (@w1 * direction), y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d1 + @w2, @options[:wall_color])
          canvas.fill_rect(x - (@w1 * direction), y + @d2 - @w2, x + (@d1 + @w2) * direction, y + @d2 + @w1, @options[:wall_color])
        end

        if wall
          canvas.fill_rect(x + (@d1 - @w1) * direction, y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d2 + @w2, @options[:wall_color])
        end
      end
    end
  end
end
