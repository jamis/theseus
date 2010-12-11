require 'theseus/maze'

module Theseus
  class Solver
    def initialize(maze, a=maze.start, b=maze.finish)
      @maze = maze
      @visits = Array.new(@maze.height) { Array.new(@maze.width, false) }
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
      relationship = lambda do |a, b|
        if a[0] < b[0]
          Maze::E
        elsif a[0] > b[0]
          Maze::W
        elsif a[1] < b[1]
          Maze::S
        elsif a[1] > b[1]
          Maze::N
        end
      end

      grid = Array.new(@maze.width) { Array.new(@maze.height, 0) }
      previous = @maze.entrance
      solution.each do |step|
        if (direction = relationship[previous, step])
          grid[previous[0]][previous[1]] |= direction if @maze.valid?(previous[0], previous[1])
          grid[step[0]][step[1]] |= @maze.opposite(direction)
        end
        previous = step
      end
      
      if (direction = relationship[previous, @maze.exit])
        grid[previous[0]][previous[1]] |= direction
      end

      return grid
    end

    def next_step
      if @stack.empty?
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
            dir = (try & Maze::PRIMARY != 0) ? try : (try >> Maze::UNDER_SHIFT)
            nx, ny = x + @maze.dx(dir), y + @maze.dy(dir)
            # might be out of bounds, due to the entrance/exit passages
            next unless @maze.valid?(nx, ny) && !@visits[ny][nx]

            @visits[ny][nx] = true
            ncell = @maze[nx, ny]
            p = [nx, ny]

            if ncell & (dir << Maze::UNDER_SHIFT) != 0 # underpass
              directions = [dir << Maze::UNDER_SHIFT]
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
