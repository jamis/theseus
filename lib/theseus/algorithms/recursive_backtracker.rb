require 'theseus/algorithms/base'

module Theseus
  module Algorithms
    # The recursive backtracking algorithm is a quick, flexible algorithm
    # for generating mazes. It tends to produce mazes with fewer dead-ends
    # than algorithms like Kruskal's or Prim's. 
    class RecursiveBacktracker < Base
      # The x-coordinate that the generation algorithm will consider next.
      attr_reader :x

      # The y-coordinate that the generation algorithm will consider next.
      attr_reader :y

      def initialize(maze, options={}) #:nodoc:
        super

        loop do
          @y = rand(@maze.height)
          @x = rand(@maze.row_length(@y))
          break if @maze.valid?(@x, @y)
        end

        @tries = @maze.potential_exits_at(@x, @y).sort_by { rand }
        @stack = []
      end

      def do_step #:nodoc:
        direction = next_direction or return false
        nx, ny = @maze.move(@x, @y, direction)

        @maze.apply_move_at(@x, @y, direction)

        # if (nx,ny) is already visited, then we're weaving (moving either over
        # or under the existing passage).
        nx, ny, direction = @maze.perform_weave(@x, @y, nx, ny, direction) if @maze[nx, ny] != 0

        @maze.apply_move_at(nx, ny, @maze.opposite(direction))

        @stack.push([@x, @y, @tries])
        @tries = @maze.potential_exits_at(nx, ny).sort_by { rand }
        @tries.push direction if @tries.include?(direction) unless rand(100) < @maze.randomness
        @x, @y = nx, ny

        return true
      end

      private

      # Returns the next direction that ought to be attempted by the recursive
      # backtracker. This will also handle the backtracking. If there are no
      # more directions to attempt, and the stack is empty, this will return +nil+.
      def next_direction #:nodoc:
        loop do
          direction = @tries.pop
          nx, ny = @maze.move(@x, @y, direction)

          if @maze.valid?(nx, ny) && (@maze[@x, @y] & (direction | (direction << Maze::UNDER_SHIFT)) == 0)
            if @maze[nx, ny] == 0
              return direction
            elsif !@maze.dead?(@maze[nx, ny]) && @maze.weave > 0 && rand(100) < @maze.weave
              # see if we can weave over/under the cell at (nx,ny)
              return direction if @maze.weave_allowed?(@x, @y, nx, ny, direction)
            end
          end

          while @tries.empty?
            if @stack.empty?
              @pending = false
              return nil
            else
              @x, @y, @tries = @stack.pop
            end
          end
        end
      end

    end
  end
end
