require 'theseus/maze'

module Theseus
  # A "sigma" maze is one in which the field is tesselated into hexagons.
  # Trying to map such a field onto a two-dimensional grid is a little tricky;
  # Theseus does so by treating a single row as the hexagon in the first
  # column, then the hexagon below and to the right, then the next hexagon
  # above and to the right (on a line with the first hexagon), and so forth.
  # For example, the following grid consists of two rows of 8 cells each:
  #
  #    _   _   _   _
  #   / \_/ \_/ \_/ \_
  #   \_/ \_/ \_/ \_/ \ 
  #   / \_/ \_/ \_/ \_/ 
  #   \_/ \_/ \_/ \_/ \ 
  #     \_/ \_/ \_/ \_/ 
  #
  # SigmaMaze supports weaving, but not symmetry (yet).
  #
  #   maze = Theseus::SigmaMaze.generate(width: 10)
  #   puts maze
  class SigmaMaze < Maze

    # Because of how the cells are positioned relative to other cells in
    # the same row, the definition of the diagonal walls changes depending
    # on whether a cell is "shifted" (e.g. moved down a half-row) or not.
    #
    #    ____        ____
    #   / N  \      /
    #  /NW  NE\____/
    #  \W    E/ N  \
    #   \_S__/W    E\____
    #        \SW  SE/
    #         \_S__/
    #
    # Thus, if a cell is shifted, W/E are in the upper diagonals, otherwise
    # they are in the lower diagonals. It is important that W/E always point
    # to cells in the same row, so that the #dx and #dy methods do not need
    # to be overridden.
    #
    # This change actually makes it fairly easy to generalize the other
    # operations, although weaving needs special attention (see #weave_allowed?
    # and #perform_weave).
    def potential_exits_at(x, y) #:nodoc:
      [N, S, E, W] + 
        ((x % 2 == 0) ? [NW, NE] : [SW, SE])
    end

    private

    # This maps which axis the directions share, depending on whether a cell
    # is shifted (+true+) or not (+false+). For example, in a non-shifted cell,
    # E is on a line with NW, so AXIS_MAP[false][E] returns NW (and vice versa).
    # This is used in the weaving algorithms to determine which direction an
    # UNDER passage moves as it passes under a cell.
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
    def exit_wound(entrance_direction, shifted) #:nodoc:
      # if moving W into the cell, then entrance_direction == W. To determine
      # the axis within the new cell, we reverse it to find the wall within the
      # cell that was penetrated (opposite(W) == E), and then
      # look it up in the AXIS_MAP (E<->NW or E<->SW, depending on the cell position)
      entrance_wall = opposite(entrance_direction)
      AXIS_MAP[shifted][entrance_wall]
    end

    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction) #:nodoc:
      # disallow a weave if there is already a weave at this cell
      return false if @cells[thru_y][thru_x] & UNDER != 0

      pass_thru = exit_wound(direction, thru_x % 2 != 0)
      out_x, out_y = move(thru_x, thru_y, pass_thru)
      return valid?(out_x, out_y) && @cells[out_y][out_x] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
      shifted = to_x % 2 != 0
      pass_thru = exit_wound(direction, shifted)

      apply_move_at(to_x, to_y, pass_thru << UNDER_SHIFT)
      apply_move_at(to_x, to_y, AXIS_MAP[shifted][pass_thru] << UNDER_SHIFT)

      nx, ny = move(to_x, to_y, pass_thru)
      [nx, ny, pass_thru]
    end
  end
end
