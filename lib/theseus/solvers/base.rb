require 'theseus/maze'

module Theseus
  module Solvers
    class Base
      attr_reader :maze, :a, :b

      def initialize(maze, a=maze.start, b=maze.finish)
        @maze = maze
        @a = a
        @b = b
        @solution = nil
      end

      def solved?
        @solution != nil
      end

      def solution
        solve unless solved?
        @solution
      end

      def solve
        while !solved?
          step
        end

        self
      end

      def each
        if solved?
          solution.each { |s| yield s }
        else
          yield s while s = step
        end
      end

      def path(options={})
        path = @maze.new_path(options)
        prev = @maze.entrance

        (@solution || current_solution).each do |pt|
          how = path.link(prev, pt)
          path.set(pt, how)
          prev = pt
        end

        how = path.link(prev, @maze.exit)
        path.set(@maze.exit, how)

        path
      end
    end
  end
end
