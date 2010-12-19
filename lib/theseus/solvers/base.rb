require 'theseus/maze'

module Theseus
  module Solvers
    # The abstract superclass for solver implementations. It simply provides
    # some helper methods that implementations would otherwise have to duplicate.
    class Base
      # The maze object that this solver will provide a solution for.
      attr_reader :maze

      # The point (2-tuple array) at which the solution path should begin.
      attr_reader :a

      # The point (2-tuple array) at which the solution path should end.
      attr_reader :b

      # Create a new solver instance for the given maze, using the given
      # start (+a+) and finish (+b+) points. The solution will not be immediately
      # generated; to do so, use the #step or #solve methods.
      def initialize(maze, a=maze.start, b=maze.finish)
        @maze = maze
        @a = a
        @b = b
        @solution = nil
      end

      # Returns +true+ if the solution has been generated.
      def solved?
        @solution != nil
      end

      # Returns the solution path as an array of 2-tuples, beginning with #a and
      # ending with #b. If the solution has not yet been generated, this will
      # generate the solution first, and then return it.
      def solution
        solve unless solved?
        @solution
      end

      # Generates the solution to the maze, and returns +self+. If the solution
      # has already been generated, this does nothing.
      def solve
        while !solved?
          step
        end

        self
      end

      # If the maze is solved, this yields each point in the solution, in order.
      #
      # If the maze has not yet been solved, this yields the result of calling
      # #step, until the maze has been solved.
      def each
        if solved?
          solution.each { |s| yield s }
        else
          yield s while s = step
        end
      end

      # Returns the solution (or, if the solution is not yet fully generated,
      # the current_solution) as a Theseus::Path object.
      def to_path(options={})
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

      # Returns the current (potentially partial) solution to the maze. This
      # is for use while the algorithm is running, so that the current best-solution
      # may be inspected (or displayed).
      def current_solution
        raise NotImplementedError, "solver subclasses must implement #current_solution"
      end

      # Runs a single iteration of the solution algorithm. Returns +false+ if the
      # algorithm has completed, and non-nil otherwise. The return value is
      # algorithm-dependent.
      def step
        raise NotImplementedError, "solver subclasses must implement #step"
      end
    end
  end
end
