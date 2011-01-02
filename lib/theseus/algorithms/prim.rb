require 'theseus/algorithms/base'

module Theseus
  module Algorithms
    class Prim < Base
      IN       = 0x10000 # indicate that a cell, though blank, is part of the IN set
      FRONTIER = 0x20000 # indicate that a cell is part of the frontier set

      def initialize(maze, options={}) #:nodoc:
        super

        if @maze.weave > 0
          raise ArgumentError, "weave mazes cannot be generated with prim's algorithm"
        end

        @frontier = []

        loop do
          y = rand(@maze.height)
          x = rand(@maze.row_length(y))
          next unless @maze.valid?(x, y)

          mark_cell(x, y)
          break
        end
      end

      # Iterates over each cell in the frontier space, yielding the coordinates
      # of each one.
      def each_frontier
        @frontier.each do |x, y|
          yield x, y
        end
      end

      def do_step #:nodoc:
        if rand(100) < @maze.randomness
          x, y = @frontier.delete_at(rand(@frontier.length))
        else
          x, y = @frontier.pop
        end

        neighbors = find_neighbors_of(x, y)
        direction, nx, ny = neighbors[rand(neighbors.length)]

        @maze.apply_move_at(x, y, direction)
        @maze.apply_move_at(nx, ny, @maze.opposite(direction))

        mark_cell(x, y)

        @pending = @frontier.any?
      end

      private

      def mark_cell(x, y) #:nodoc:
        @maze[x, y] |= IN
        @maze[x, y] &= ~FRONTIER

        @maze.potential_exits_at(x, y).each do |dir|
          nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
          if @maze.valid?(nx, ny) && @maze[nx, ny] == 0
            @maze[nx, ny] |= FRONTIER
            @frontier << [nx, ny]
          end
        end
      end

      def find_neighbors_of(x, y) #:nodoc:
        list = []

        @maze.potential_exits_at(x, y).each do |dir|
          nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
          list << [dir, nx, ny] if @maze.valid?(nx,ny) && @maze[nx, ny] & IN != 0
        end

        return list
      end
    end
  end
end
