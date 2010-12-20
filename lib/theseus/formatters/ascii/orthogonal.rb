# encoding: UTF-8

require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      # Renders an OrthogonalMaze to an ASCII representation.
      #
      # The ASCII formatter for the OrthogonalMaze actually supports three different
      # output types:
      #
      # [:plain]    Uses standard 7-bit ASCII characters. Width is 2x+1, height is
      #             y+1. This mode cannot render weave mazes without significant
      #             ambiguity.
      # [:unicode]  Uses unicode characters to render cleaner lines. Width is
      #             3x, height is 2y. This mode has sufficient detail to correctly
      #             render mazes with weave!
      # [:lines]    Draws passages as lines, using unicode characters. Width is
      #             x, height is y. This mode can render weave mazes, but with some
      #             ambiguity.
      #
      # The :plain mode is the default, but you can specify a different one using
      # the :mode option.
      #
      # You shouldn't ever need to instantiate this class directly. Rather, use
      # OrthogonalMaze#to(:ascii) (or OrthogonalMaze#to_s to get the string directly).
      class Orthogonal < ASCII
        # Returns the dimensions of the given maze, rendered in the given mode.
        # The +mode+ must be +:plain+, +:unicode+, or +:lines+.
        def self.dimensions_for(maze, mode)
          case mode
          when :plain, nil then 
            [maze.width * 2 + 1, maze.height + 1]
          when :unicode then
            [maze.width * 3, maze.height * 2]
          when :lines then
            [maze.width, maze.height]
          else
            abort "unknown mode #{mode.inspect}"
          end
        end

        # Create and return a fully initialized ASCII canvas. The +options+
        # parameter may specify a +:mode+ parameter, as described in the documentation
        # for this class.
        def initialize(maze, options={})
          mode = options[:mode] || :plain

          width, height = self.class.dimensions_for(maze, mode)
          super(width, height)

          maze.height.times do |y|
            length = maze.row_length(y)
            length.times do |x|
              case mode
              when :plain then draw_plain_cell(maze, x, y)
              when :unicode then draw_unicode_cell(maze, x, y)
              when :lines then draw_line_cell(maze, x, y)
              end
            end
          end
        end

        private

        def draw_plain_cell(maze, x, y) #:nodoc:
          c = maze[x, y]
          return if c == 0

          px, py = x * 2, y

          cnw = maze.valid?(x-1,y-1) ? maze[x-1,y-1] : 0
          cn  = maze.valid?(x,y-1) ? maze[x,y-1] : 0
          cne = maze.valid?(x+1,y-1) ? maze[x+1,y-1] : 0
          cse = maze.valid?(x+1,y+1) ? maze[x+1,y+1] : 0
          cs  = maze.valid?(x,y+1) ? maze[x,y+1] : 0
          csw = maze.valid?(x-1,y+1) ? maze[x-1,y+1] : 0

          if c & Maze::N == 0
            self[px, py] = "_" if y == 0 || (cn == 0 && cnw == 0) || cnw & (Maze::E | Maze::S) == Maze::E
            self[px+1, py] = "_"
            self[px+2, py] = "_" if y == 0 || (cn == 0 && cne == 0) || cne & (Maze::W | Maze::S) == Maze::W
          end

          if c & Maze::S == 0
            bottom = y+1 == maze.height
            self[px, py+1] = "_" if bottom || (cs == 0 && csw == 0) || csw & (Maze::E | Maze::N) == Maze::E
            self[px+1, py+1] = "_"
            self[px+2, py+1] = "_" if bottom || (cs == 0 && cse == 0) || cse & (Maze::W | Maze::N) == Maze::W
          end

          self[px, py+1] = "|" if c & Maze::W == 0
          self[px+2, py+1] = "|" if c & Maze::E == 0
        end

        UTF8_SPRITES = [
          ["   ", "   "], # " "
          ["│ │", "└─┘"], # "╵"
          ["┌─┐", "│ │"], # "╷"
          ["│ │", "│ │"], # "│",
          ["┌──", "└──"], # "╶" 
          ["│ └", "└──"], # "└" 
          ["┌──", "│ ┌"], # "┌"
          ["│ └", "│ ┌"], # "├" 
          ["──┐", "──┘"], # "╴"
          ["┘ │", "──┘"], # "┘"
          ["──┐", "┐ │"], # "┐"
          ["┘ │", "┐ │"], # "┤"
          ["───", "───"], # "─"
          ["┘ └", "───"], # "┴"
          ["───", "┐ ┌"], # "┬"
          ["┘ └", "┐ ┌"]  # "┼"
        ]

        def draw_unicode_cell(maze, x, y) #:nodoc:
          cx, cy = 3 * x, 2 * y
          cell = maze[x, y]

          UTF8_SPRITES[cell & Maze::PRIMARY].each_with_index do |row, sy|
            row.length.times do |sx|
              char = row[sx]
              self[cx+sx, cy+sy] = char
            end
          end

          under = cell >> Maze::UNDER_SHIFT

          if under & Maze::N != 0
            self[cx,   cy] = "┴"
            self[cx+2, cy] = "┴"
          end

          if under & Maze::S != 0
            self[cx,   cy+1] = "┬"
            self[cx+2, cy+1] = "┬"
          end

          if under & Maze::W != 0
            self[cx, cy]   = "┤"
            self[cx, cy+1] = "┤"
          end

          if under & Maze::E != 0
            self[cx+2, cy]   = "├"
            self[cx+2, cy+1] = "├"
          end
        end

        UTF8_LINES = [" ", "╵", "╷", "│", "╶", "└", "┌", "├", "╴", "┘", "┐", "┤", "─", "┴", "┬", "┼"]

        def draw_line_cell(maze, x, y) #:nodoc:
          self[x, y] = UTF8_LINES[maze[x, y] & Maze::PRIMARY]
        end
      end
    end
  end
end
