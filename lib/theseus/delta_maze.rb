require 'theseus/maze'

module Theseus
  # A "delta" maze is one in which the field is tesselated into triangles. Thus,
  # each cell has three potential exits: east, west, and either north or south
  # (depending on the orientation of the cell).
  #
  #      __  __  __
  #    /\  /\  /\  /
  #   /__\/__\/__\/
  #   \  /\  /\  /\ 
  #    \/__\/__\/__\ 
  #    /\  /\  /\  /
  #   /__\/__\/__\/
  #   \  /\  /\  /\ 
  #    \/__\/__\/__\ 
  #   
  #
  # Delta mazes in Theseus do not support either weaving, or symmetry.
  #
  #   maze = Theseus::DeltaMaze.generate(width: 10)
  #   puts maze
  class DeltaMaze < Maze
    def initialize(options={}) #:nodoc:
      super
      raise ArgumentError, "weaving is not supported for delta mazes" if @weave > 0
    end

    # Returns +true+ if the cell at (x,y) is oriented so the vertex is "up", or
    # north. Cells for which this returns +true+ may have exits on the south border,
    # and cells for which it returns +false+ may have exits on the north.
    def points_up?(x, y)
      (x + y) % 2 == height % 2
    end

    def potential_exits_at(x, y) #:nodoc:
      vertical = points_up?(x, y) ? S : N

      # list the vertical direction twice. Otherwise the horizontal direction (E/W)
      # will be selected more often (66% of the time), resulting in mazes with a
      # horizontal bias.
      [vertical, vertical, E, W]
    end
  end
end
