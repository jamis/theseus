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

    def perform_weave(from_x, from_y, to_x, to_y, direction)
      apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
      apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)

      [to_x + dx(direction), to_y + dy(direction), direction]
    end

  end
end
