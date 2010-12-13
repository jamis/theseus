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

    private

    AXIS_MAP = {
      false => {
        N => S,
        S => N,
        E => NW,
        NW => E,
        W => NE,
        NE => W
      },

      true => {
        N => S,
        S => N,
        W => SE,
        SE => W,
        E => SW,
        SW => E
      }
    }

    # given a path entering in +entrance_direction+, returns the side of the
    # cell that it would exit if it passed in a straight line through the cell.
    def exit_wound(entrance_direction, shifted)
      # if moving W into the cell, then entrance_direction == W. To determine
      # the axis within the new cell, we reverse it to find the wall within the
      # cell that was penetrated (opposite(W) == E), and then
      # look it up in the AXIS_MAP (E<->NW or E<->SW, depending on the cell position)
      entrance_wall = opposite(entrance_direction)
      AXIS_MAP[shifted][entrance_wall]
    end

    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction)
      # disallow a weave if there is already a weave at this cell
      return false if @cells[thru_y][thru_x] & UNDER != 0

      pass_thru = exit_wound(direction, thru_x % 2 != 0)
      out_x, out_y = thru_x + dx(pass_thru), thru_y + dy(pass_thru)
      return valid?(out_x, out_y) && @cells[out_y][out_x] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction)
      shifted = to_x % 2 != 0
      pass_thru = exit_wound(direction, shifted)

      apply_move_at(to_x, to_y, pass_thru << UNDER_SHIFT)
      apply_move_at(to_x, to_y, AXIS_MAP[shifted][pass_thru] << UNDER_SHIFT)

      [to_x + dx(pass_thru), to_y + dy(pass_thru), pass_thru]
    end
  end
end
