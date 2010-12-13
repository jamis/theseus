require 'theseus/maze'

module Theseus
  class UpsilonMaze < Maze

    def potential_exits_at(x, y)
      if (x+y) % 2 == 0 # octogon
        [N, S, E, W, NW, NE, SW, SE]
      else # square
        [N, S, E, W]
      end
    end

    #  _   _   _     0
    # / \_/ \_/ \
    # | |_| |_| |
    # \_/ \_/ \_/    1
    # |_| |_| |_|
    # / \_/ \_/ \
    #
    def to_s
      canvas = Array.new(height * 2 + 3) { Array.new(width * 2 + 1, " ") }

      @cells.each_with_index do |row, y|
        py = y * 2
        row.each_with_index do |cell, x|
          next if cell == 0

          px = x * 2

          if (x + y) % 2 == 0 # octogon
            canvas[py][px+1]   = "_" if cell & N == 0
            canvas[py+1][px]   = "/" if cell & NW == 0
            canvas[py+1][px+2] = "\\" if cell & NE == 0
            canvas[py+2][px]   = "|" if cell & W == 0
            canvas[py+2][px+2] = "|" if cell & E == 0
            canvas[py+3][px]   = "\\" if cell & SW == 0
            canvas[py+3][px+1] = "_" if cell & S == 0
            canvas[py+3][px+2] = "/" if cell & SE == 0
          else # square
            canvas[py+1][px+1] = "_" if cell & N == 0
            canvas[py+2][px]   = "|" if cell & W == 0
            canvas[py+2][px+1] = "_" if cell & S == 0
            canvas[py+2][px+2] = "|" if cell & E == 0
          end
        end
      end

      canvas.map { |row| row.join }.join("\n")
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction)
      apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
      apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)

      [to_x + dx(direction), to_y + dy(direction), direction]
    end

  end
end
