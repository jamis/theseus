require 'theseus/maze'

module Theseus
  class Solver
    def initialize(maze, a=maze.start, b=maze.finish)
      @maze = maze
      @a = a
      @b = b
      @stack = []
    end

    def solution
      solution = []
      while step = next_step
        if step == :backtrack
          solution.pop
        else
          solution.push(step)
        end
      end
      solution
    end

    def next_step
      if @stack.empty?
        @stack.push([@a, Maze::DIRECTIONS.dup])
        return @a.dup
      elsif @stack.last[0] == @b
        return nil
      else
        x, y = @stack.last[0]
        cell = @maze[x, y]
        loop do
          try = @stack.last[1].pop

          if try.nil?
            @stack.pop
            return :backtrack
          elsif (cell & try) != 0
            dir = (try & Maze::PRIMARY != 0) ? try : (try >> 4)
            nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
            # might be out of bounds, due to the entrance/exit passages
            next unless @maze.in_bounds?(nx, ny)

            ncell = @maze[nx, ny]
            p = [nx, ny]

            if ncell & (dir << 4) != 0 # underpass
              directions = [dir << 4]
            else
              directions = Maze::DIRECTIONS - [@maze.opposite(dir)]
            end

            @stack.push([p, directions])
            return p.dup
          end
        end
      end
    end
  end
end
