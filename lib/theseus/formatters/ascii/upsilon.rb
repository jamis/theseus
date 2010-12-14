require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      #  _   _   _     0
      # / \_/ \_/ \
      # | |_| |_| |
      # \_/ \_/ \_/    1
      # |_| |_| |_|
      # / \_/ \_/ \
      #
      class Upsilon < ASCII
        def initialize(maze, options={})
          super(maze.width * 2 + 1, maze.height * 2 + 3)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              if (x + y) % 2 == 0
                draw_octogon_cell(px, py, cell)
              else
                draw_square_cell(px, py, cell)
              end
            end
          end
        end

        private

        def draw_octogon_cell(px, py, cell)
          self[px+1, py]   = "_" if cell & Maze::N == 0
          self[px, py+1]   = "/" if cell & Maze::NW == 0
          self[px+2, py+1] = "\\" if cell & Maze::NE == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
          self[px, py+3]   = "\\" if cell & Maze::SW == 0
          self[px+1, py+3] = "_" if cell & Maze::S == 0
          self[px+2, py+3] = "/" if cell & Maze::SE == 0
        end

        def draw_square_cell(px, py, cell)
          self[px+1, py+1] = "_" if cell & Maze::N == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+1, py+2] = "_" if cell & Maze::S == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
        end
      end
    end
  end
end
