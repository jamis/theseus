require 'theseus/maze'

module Theseus
  class SigmaMaze < Maze

    #     0     1     ...
    #    ____        ____
    #   / N  \      /
    #  /NW  NE\____/
    #  \W    E/ N  \
    #   \_S__/W    E\____
    #        \SW  SE/
    #         \_S__/
    #
    def potential_exits_at(x, y)
      [N, S, E, W] + 
        ((x % 2 == 0) ? [NW, NE] : [SW, SE])
    end

    #   0123456789012
    # 0  _   _   _
    # 1 / \_/ \_/ \_
    # 2 \_/ \_/ \_/ \
    # 3 / \_/ \_/ \_/
    # 4 \_/ \_/ \_/ \
    #
    def to_s
      str = ""

      str << " "
      width.times do |x|
        if x % 2 == 0
          str << ((@cells[0][x] % N == 0) ? "_" : " ")
        else
          str << "   "
        end
      end
      str << "\n"

      @cells.each_with_index do |row, y|
        r1 = (@cells[y][0] & NW == 0) ? "/" : " "
        r2 = (@cells[y][0] & W == 0) ? "\\" : " "

        last_y = (y+1 == @cells.length)
        r3 = last_y ? "  " : nil

        row.each_with_index do |cell, x|
          if x % 2 == 0
            r1 << ((@cells[y][x] & NE == 0) ? " \\" : "  ")
            r2 << ((@cells[y][x] & S == 0) ? "_" : " ")
            r2 << ((@cells[y][x] & E == 0) ? "/ " : "  ")
          else
            r1 << ((@cells[y][x] & N == 0) ? "_" : " ")
            r1 << ((valid?(x+1, y) && @cells[y][x+1] & NW == 0) ? "/" : " ")
            r2 << ((@cells[y][x] & E == 0) ? "\\" : " ")

            if x+1 == row.length && valid?(x,y-1)
              r1.chop!
              r1 << ((@cells[y-1][x] & SE == 0) ? "/" : "")
            end

            if last_y
              r3 << ((@cells[y][x] & SW == 0) ? "\\" : " ")
              r3 << ((@cells[y][x] & S == 0) ? "_" : " ")
              r3 << ((@cells[y][x] & SE == 0) ? "/ " : "  ")
            end
          end
        end

        str << r1 << "\n" << r2 << "\n"
        str << r3 if r3
      end

      str
    end
  end
end
