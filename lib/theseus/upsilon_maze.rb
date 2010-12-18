require 'theseus/maze'

module Theseus
  # An upsilon maze is one in which the field is tesselated into octogons and
  # squares:
  #
  #    _   _   _   _
  #   / \_/ \_/ \_/ \
  #   | |_| |_| |_| |
  #   \_/ \_/ \_/ \_/
  #   |_| |_| |_| |_|
  #   / \_/ \_/ \_/ \
  #   | |_| |_| |_| |
  #   \_/ \_/ \_/ \_/
  #
  # Upsilon mazes in Theseus support weaving, but not symmetry (yet).
  #
  #   maze = Theseus::UpsilonMaze.generate(width: 10)
  #   puts maze
  class UpsilonMaze < Maze
    def potential_exits_at(x, y) #:nodoc:
      if (x+y) % 2 == 0 # octogon
        [N, S, E, W, NW, NE, SW, SE]
      else # square
        [N, S, E, W]
      end
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
      apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
      apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)

      nx, ny = move(to_x, to_y, direction)
      [nx, ny, direction]
    end
  end
end
