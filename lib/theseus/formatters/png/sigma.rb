require 'theseus/solver'
require 'theseus/formatters/png'

module Theseus
  module Formatters
    class PNG
      class Sigma < PNG
        def initialize(maze, options={})
          super

          width = options[:outer_padding] * 2 + (3 * maze.width + 1) * options[:cell_size] / 4
          height = options[:outer_padding] * 2 + maze.height * options[:cell_size] + options[:cell_size] / 2

          canvas = ChunkyPNG::Image.new(width, height, options[:background])

          if options[:solution]
            solution_grid = Solver.new(maze).solution_grid
          end

          maze.height.times do |y|
            py = options[:outer_padding] + y * options[:cell_size]
            maze.row_length(y).times do |x|
              px = options[:outer_padding] + x * 3 * options[:cell_size] / 4.0
              shifted = (x % 2 != 0)
              dy = shifted ? (options[:cell_size] / 2.0) : 0
              draw_cell(canvas, shifted, px, py+dy, maze[x, y], solution_grid ? solution_grid[x][y] : 0)
            end
          end

          @blob = canvas.to_blob
        end

        def move(point, dx, dy)
          [point[0] + dx, point[1] + dy]
        end

        def line(canvas, p1, p2, color)
          canvas.line(p1[0].round, p1[1].round, p2[0].round, p2[1].round, color)
        end

        def draw_cell(canvas, shifted, x, y, cell, solution)
          return if cell == 0

          color = (solution & cell != 0) ? :solution_color : :cell_color

          size = options[:cell_size] - options[:cell_padding] * 2
          s4 = size / 4.0

          p1 = [x + options[:cell_padding] + s4, y + options[:cell_padding]]
          p2 = [x + options[:cell_size] - options[:cell_padding] - s4, p1[1]]
          p3 = [x + options[:cell_padding] + size, y + options[:cell_size] / 2.0]
          p4 = [p2[0], y + options[:cell_size] - options[:cell_padding]]
          p5 = [p1[0], p4[1]]
          p6 = [x + options[:cell_padding], p3[1]]

          fill_poly(canvas, [p1, p2, p3, p4, p5, p6], options[color])

          n  = (cell & Maze::N == 0)
          s  = (cell & Maze::S == 0)
          nw = (cell & (shifted ? Maze::W : Maze::NW) == 0)
          ne = (cell & (shifted ? Maze::E : Maze::NE) == 0)
          sw = (cell & (shifted ? Maze::SW : Maze::W) == 0)
          se = (cell & (shifted ? Maze::SE : Maze::E) == 0)

          
          line(canvas, p1, p2, options[:wall_color]) if n
          line(canvas, p2, p3, options[:wall_color]) if ne
          line(canvas, p3, p4, options[:wall_color]) if se
          line(canvas, p4, p5, options[:wall_color]) if s
          line(canvas, p5, p6, options[:wall_color]) if sw
          line(canvas, p6, p1, options[:wall_color]) if nw
        end
      end
    end
  end
end

