require 'theseus/solver'
require 'theseus/formatters/png'

module Theseus
  module Formatters
    module Delta
      class PNG < Theseus::Formatters::PNG
        def initialize(maze, options={})
          super

          height = options[:outer_padding] * 2 + maze.height * options[:cell_size]
          width = options[:outer_padding] * 2 + ((maze.width + 1) / 2) * options[:cell_size]

          canvas = ChunkyPNG::Image.new(width, height, options[:background])

          if options[:solution]
            solution_grid = Solver.new(maze).solution_grid
          end

          maze.height.times do |y|
            py = options[:outer_padding] + y * options[:cell_size]
            maze.row_length(y).times do |x|
              px = options[:outer_padding] + x * options[:cell_size] / 2.0
              draw_cell(canvas, maze.points_up?(x,y), px, py, maze[x, y], solution_grid ? solution_grid[x][y] : 0)
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

        def draw_cell(canvas, up, x, y, cell, solution)
          return if cell == 0

          color = (solution & cell != 0) ? :solution_color : :cell_color

          p1 = [x + options[:cell_size] / 2.0, up ? (y + options[:cell_padding]) : (y + options[:cell_size] - options[:cell_padding])]
          p2 = [x + options[:cell_padding], up ? (y + options[:cell_size] - options[:cell_padding]) : (y + options[:cell_padding])]
          p3 = [x + options[:cell_size] - options[:cell_padding], p2[1]]

          if cell & (Maze::N << Maze::UNDER_SHIFT) != 0
            clr = (solution & (Maze::N << Maze::UNDER_SHIFT) != 0) ? :solution_color : :cell_color
            fill_rect(canvas, x + options[:cell_padding], y,
              x + options[:cell_size] - options[:cell_padding], y + options[:cell_size],
              options[clr])
          end

          fill_poly(canvas, [p1, p2, p3], options[color])

          if cell & (Maze::N | Maze::S) != 0
            clr = (solution & Maze::N != 0) ? :solution_color : :cell_color
            dy = options[:cell_padding]
            sign = (cell & Maze::N != 0) ? -1 : 1
            r1, r2 = p2, move(p3, 0, sign*dy)
            fill_rect(canvas, r1[0].round, r1[1].round, r2[0].round, r2[1].round, options[clr])
            line(canvas, r1, move(r1, 0, sign*dy), options[:wall_color])
            line(canvas, r2, move(r2, 0, dy-1), options[:wall_color])
          else
            line(canvas, p2, p3, options[:wall_color])
          end

          dx = options[:cell_padding]+1
          if cell & ANY_W != 0
            r1, r2, r3, r4 = move(p1,1,0), move(p1,-dx,0), move(p2,-dx,0), move(p2,1,0)
            fill_poly(canvas, [r1, r2, r3, r4], options[(solution & ANY_W != 0) ? :solution_color : :cell_color])
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::W == 0
            line(canvas, p1, p2, options[:wall_color])
          end

          if cell & ANY_E != 0
            r1, r2, r3, r4 = move(p1,-1,0), move(p1,dx,0), move(p3,dx,0), move(p3,-1,0)
            fill_poly(canvas, [r1, r2, r3, r4], options[(solution & ANY_W != 0) ? :solution_color : :cell_color])
            line(canvas, r1, r2, options[:wall_color])
            line(canvas, r3, r4, options[:wall_color])
          end

          if cell & Maze::E == 0
            line(canvas, p3, p1, options[:wall_color])
          end

          #north = cell & Maze::N == Maze::N
          #north_under = (cell >> Maze::UNDER_SHIFT) & Maze::N == Maze::N
          #south = cell & Maze::S == Maze::S
          #south_under = (cell >> Maze::UNDER_SHIFT) & Maze::S == Maze::S
          #west = cell & Maze::W == Maze::W
          #west_under = (cell >> Maze::UNDER_SHIFT) & Maze::W == Maze::W
          #east = cell & Maze::E == Maze::E
          #east_under = (cell >> Maze::UNDER_SHIFT) & Maze::E == Maze::E

          #draw_vertical(canvas, x, y, 1, north || north_under, !north || north_under, solution & ANY_N != 0 ? :solution_color : :cell_color) 
          #draw_vertical(canvas, x, y + options[:cell_size], -1, south || south_under, !south || south_under, solution & ANY_S != 0 ? :solution_color : :cell_color)
          #draw_horizontal(canvas, x, y, 1, west || west_under, !west || west_under, solution & ANY_W != 0 ? :solution_color : :cell_color)
          #draw_horizontal(canvas, x + options[:cell_size], y, -1, east || east_under, !east || east_under, solution & ANY_E != 0 ? :solution_color : :cell_color)
        end
      end
    end
  end
end

