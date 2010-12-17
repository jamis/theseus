require 'theseus/solvers/base'

module Theseus
  module Solvers
    class Backtracker < Base
      def initialize(maze, a=maze.start, b=maze.finish)
        super
        @visits = Array.new(@maze.height) { Array.new(@maze.width, 0) }
        @stack = []
      end

      VISIT_MASK = { false => 1, true => 2 }

      def current_solution
        @stack[1..-1].map { |item| item[0] }
      end

      def step
        if @stack == [:fail]
          return false
        elsif @stack.empty?
          @stack.push(:fail)
          @stack.push([@a, @maze.potential_exits_at(@a[0], @a[1]).dup])
          return @a.dup
        elsif @stack.last[0] == @b
          @solution = @stack[1..-1].map { |pt, tries| pt }
          return false
        else
          x, y = @stack.last[0]
          cell = @maze[x, y]
          loop do
            try = @stack.last[1].pop

            if try.nil?
              spot = @stack.pop
              x, y = spot[0]
              return :backtrack
            elsif (cell & try) != 0
              # is the current path an "under" path for the current cell (x,y)?
              is_under = (try & Maze::UNDER != 0)

              dir = is_under ? (try >> Maze::UNDER_SHIFT) : try
              opposite = @maze.opposite(dir)

              nx, ny = @maze.move(x, y, dir)

              # is the new path an "under" path for the next cell (nx,ny)?
              going_under = @maze[nx, ny] & (opposite << Maze::UNDER_SHIFT) != 0

              # might be out of bounds, due to the entrance/exit passages
              next if !@maze.valid?(nx, ny) || (@visits[ny][nx] & VISIT_MASK[going_under] != 0)

              @visits[ny][nx] |= VISIT_MASK[going_under]
              ncell = @maze[nx, ny]
              p = [nx, ny]

              if ncell & (opposite << Maze::UNDER_SHIFT) != 0 # underpass
                unders = (ncell & Maze::UNDER) >> Maze::UNDER_SHIFT
                exit_dir = unders & ~opposite
                directions = [exit_dir << Maze::UNDER_SHIFT]
              else
                directions = @maze.potential_exits_at(nx, ny) - [@maze.opposite(dir)]
              end

              @stack.push([p, directions])
              return p.dup
            end
          end
        end
      end
    end
  end
end
