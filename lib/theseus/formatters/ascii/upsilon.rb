require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      # Renders an UpsilonMaze to an ASCII representation, using 3 characters
      # horizontally and 4 characters vertically to represent a single octagonal
      # cell, and 3 characters horizontally and 2 vertically to represent a square
      # cell.
      #    _   _   _  
      #   / \_/ \_/ \ 
      #   | |_| |_| |
      #   \_/ \_/ \_/ 
      #   |_| |_| |_|
      #   / \_/ \_/ \ 
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # UpsilonMaze#to(:ascii) (or UpsilonMaze#to_s to get the string directly).
      class Upsilon < ASCII
        # Returns a new Sigma canvas for the given maze (which should be an
        # instance of SigmaMaze). The +options+ parameter is not used.
        #
        # The returned object will be fully initialized, containing an ASCII
        # representation of the given SigmaMaze.
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

        def draw_octogon_cell(px, py, cell) #:nodoc:
          self[px+1, py]   = "_" if cell & Maze::N == 0
          self[px, py+1]   = "/" if cell & Maze::NW == 0
          self[px+2, py+1] = "\\" if cell & Maze::NE == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
          self[px, py+3]   = "\\" if cell & Maze::SW == 0
          self[px+1, py+3] = "_" if cell & Maze::S == 0
          self[px+2, py+3] = "/" if cell & Maze::SE == 0
        end

        def draw_square_cell(px, py, cell) #:nodoc:
          self[px+1, py+1] = "_" if cell & Maze::N == 0
          self[px, py+2]   = "|" if cell & Maze::W == 0
          self[px+1, py+2] = "_" if cell & Maze::S == 0
          self[px+2, py+2] = "|" if cell & Maze::E == 0
        end
      end
    end
  end
end
