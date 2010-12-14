require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      class Delta < ASCII
        #          __
        #        /\  /
        #       /__\/
        #      /\  /\
        #     /__\/__\
        #    /\  /\  /\
        #   /__\/__\/__\
        #
        def initialize(maze, options={})
          super((maze.width + 1) * 2, maze.height * 2 + 1)

          maze.height.times do |y|
            py = y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = x * 2

              if maze.points_up?(x, y)
                if cell & Maze::W == 0
                  self[px+1,py+1] = "/"
                  self[px,py+2] = "/"
                elsif y < 1
                  self[px+1,py] = "_"
                end

                if cell & Maze::E == 0
                  self[px+2,py+1] = "\\"
                  self[px+3,py+2] = "\\"
                elsif y < 1
                  self[px+2,py] = "_"
                end

                if cell & Maze::S == 0
                  self[px+1,py+2] = self[px+2,py+2] = "_"
                end
              else
                if cell & Maze::W == 0
                  self[px,py+1] = "\\"
                  self[px+1,py+2] = "\\"
                elsif x > 0 && maze[x-1,y] & Maze::S == 0
                  self[px+1,py+2] = "_"
                end

                if cell & Maze::E == 0
                  self[px+3,py+1] = "/"
                  self[px+2,py+2] = "/"
                elsif x < maze.row_length(y) && maze[x+1,y] & Maze::S == 0
                  self[px+2,py+2] = "_"
                end

                if cell & Maze::N == 0
                  self[px+1,py] = self[px+2,py] = "_"
                end
              end
            end
          end
        end
      end
    end
  end
end
