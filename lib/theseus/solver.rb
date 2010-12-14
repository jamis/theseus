require 'theseus/maze'

module Theseus
  class Solver
    def initialize(maze, a=maze.start, b=maze.finish)
      @maze = maze
      @visits = Array.new(@maze.height) { Array.new(@maze.width, 0) }
      @a = a
      @b = b
      @stack = []
    end

    def each
      while step = next_step
        yield step
      end
    end

    def solution
      solution = []
      each do |step|
        if step == :backtrack
          solution.pop
        else
          solution.push(step)
        end
      end
      solution
    end

    def solution_grid
      grid = Array.new(@maze.width) { Array.new(@maze.height, 0) }
      previous = @maze.entrance
      solution.each do |step|
        if (direction = @maze.relative_direction(previous, step))
          grid[previous[0]][previous[1]] |= direction if @maze.valid?(previous[0], previous[1])
          grid[step[0]][step[1]] |= @maze.opposite(direction)
        end
        previous = step
      end
      
      if (direction = @maze.relative_direction(previous, @maze.exit))
        grid[previous[0]][previous[1]] |= direction
      end

      return grid
    end

    VISIT_MASK = { false => 1, true => 2 }

    def next_step
      if @stack == [:fail]
        return nil
      elsif @stack.empty?
        @stack.push(:fail)
        @stack.push([@a, @maze.potential_exits_at(@a[0], @a[1]).dup])
        return @a.dup
      elsif @stack.last[0] == @b
        return nil
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
