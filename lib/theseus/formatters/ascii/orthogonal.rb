# encoding: UTF-8

require 'theseus/formatters/ascii'

module Theseus
  module Formatters
    class ASCII
      class Orthogonal < ASCII
        def initialize(maze, options={})
          mode = options[:mode] || :plain

          super(mode == :utf8_lines ? maze.width : maze.width * 3,
                mode == :utf8_lines ? maze.height : maze.height * 2)

          maze.height.times do |y|
            py = (mode == :utf8_lines) ? y : y * 2
            maze.row_length(y).times do |x|
              cell = maze[x, y]
              next if cell == 0

              px = (mode == :utf8_lines) ? x : x * 3
              
              draw_cell(cell, px, py, mode)
            end
          end
        end

        def draw_cell(cell, x, y, mode)
          case mode
          when :plain then draw_plain_ascii_cell(cell, x, y)
          when :utf8_lines then draw_utf8_lines_cell(cell, x, y)
          when :utf8_halls then draw_utf8_halls_cell(cell, x, y)
          else raise ArgumentError, "unknown mode #{mode.inspect}"
          end
        end

        SIMPLE_SPRITES = [
          ["   ", "   "], # " "     
          ["| |", "+-+"], # "╵"    N
          ["+-+", "| |"], # "╷"    S
          ["| |", "| |"], # "│",   NS
          ["+--", "+--"], # "╶"    E
          ["| .", "+--"], # "└"    NE
          ["+--", "| ."], # "┌"    SE
          ["| .", "| ."], # "├"    NSE
          ["--+", "--+"], # "╴"    W
          [". |", "--+"], # "┘"    NW
          ["--+", ". |"], # "┐"    SW
          [". |", ". |"], # "┤"    NSW
          ["---", "---"], # "─"    EW
          [". .", "---"], # "┴"    EWN
          ["---", ". ."], # "┬"    EWS
          [". .", ". ."]  # "┼"    EWNS
        ]

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

        UTF8_LINES = [" ", "╵", "╷", "│", "╶", "└", "┌", "├", "╴", "┘", "┐", "┤", "─", "┴", "┬", "┼"]

        def draw_sprite_at(x, y, sprite)
          sprite.each_with_index do |row, sy|
            row.length.times do |sx|
              char = row[sx]
              self[x+sx, y+sy] = char
            end
          end
        end

        def draw_plain_ascii_cell(cell, x, y)
          draw_sprite_at(x, y, SIMPLE_SPRITES[cell & Maze::PRIMARY])
        end

        def draw_utf8_halls_cell(cell, x, y)
          draw_sprite_at(x, y, UTF8_SPRITES[cell & Maze::PRIMARY])
        end

        def draw_utf8_lines_cell(cell, x, y)
          self[x, y] = UTF8_LINES[cell & Maze::PRIMARY]
        end

      end
    end
  end
end
