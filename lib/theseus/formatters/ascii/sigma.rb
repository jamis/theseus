require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      # Renders a SigmaMaze to an ASCII representation, using 3 characters
      # horizontally and 3 characters vertically to represent a single cell.
      #    _   _   _
      #   / \_/ \_/ \_
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #   / \_/ \_/ \_/
      #   \_/ \_/ \_/ \ 
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # SigmaMaze#to(:ascii) (or SigmaMaze#to_s to get the string directly).
      class Sigma < ASCII
        # Returns a new Sigma canvas for the given maze (which should be an
        # instance of SigmaMaze). The +options+ parameter is not used.
        #
        # The returned object will be fully initialized, containing an ASCII
        # representation of the given SigmaMaze.
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
