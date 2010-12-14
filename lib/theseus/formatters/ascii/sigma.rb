require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      #   0123456789012
      # 0  _   _   _
      # 1 / \_/ \_/ \_
      # 2 \_/ \_/ \_/ \
      # 3 / \_/ \_/ \_/
      # 4 \_/ \_/ \_/ \
      # 5 / \_/ \_/ \_/
      # 6 \_/ \_/ \_/ \
      # 7 / \_/ \_/ \_/
      # 8 \_/ \_/ \_/ \
      #
      class Sigma < ASCII
        def initialize(maze, options={})
          super(maze.width * 2 + 2, maze.height * 2 + 2)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              shifted = x % 2 != 0
              ry = shifted ? py+1 : py

              nw = shifted ? Maze::W : Maze::NW
              ne = shifted ? Maze::E : Maze::NE
              sw = shifted ? Maze::SW : Maze::W
              se = shifted ? Maze::SE : Maze::E

              self[px+1,ry]   = "_" if cell & Maze::N == 0
              self[px,ry+1]   = "/" if cell & nw == 0
              self[px+2,ry+1] = "\\" if cell & ne == 0
              self[px,ry+2]   = "\\" if cell & sw == 0
              self[px+1,ry+2] = "_" if cell & Maze::S == 0
              self[px+2,ry+2] = "/" if cell & se == 0
            end
          end
        end
      end
    end
  end
end
