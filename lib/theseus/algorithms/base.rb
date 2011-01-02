module Theseus
  module Algorithms
    # A minimal abstract superclass for maze algorithms to descend
    # from, mostly as a helper to provide some basic, common
    # functionality.
    class Base
      # The maze object that the algorithm will operate on.
      attr_reader :maze

      # Create a new algorithm object that will operate on the
      # given maze.
      def initialize(maze, options={})
        @maze = maze
        @pending = true
      end

      # Returns true if the algorithm has not yet completed.
      def pending?
        @pending
      end

      # Execute a single step of the algorithm. Return true
      # if the algorithm is still pending, or false if it has
      # completed.
      def step
        return false unless pending?
        do_step
      end
    end
  end
end
