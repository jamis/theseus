require 'theseus/maze'

module Theseus
  class DeltaMaze < Maze
    def initialize(options={})
      super
      raise ArgumentError, "weaving is not supported for delta mazes" if @weave > 0
    end

    def points_up?(x, y)
      (x + y) % 2 == height % 2
    end

    def potential_exits_at(x, y)
      vert = points_up?(x, y) ? S : N
      [vert, vert, E, W] # vert twice, otherwise E/W is extra likely to be selected
    end
  end
end
