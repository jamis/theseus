module Theseus
  class Path
    attr_reader :paths, :cells

    def initialize(maze, meta={})
      @maze = maze
      @paths = Hash.new(0)
      @cells = Hash.new(0)
      @meta = meta
    end

    def [](key)
      @meta[key]
    end

    def set(point, how=:over)
      @cells[point] |= (how == :over ? 1 : 2)
    end

    def link(from, to)
      if (direction = @maze.relative_direction(from, to))
        opposite = @maze.opposite(direction)

        if @maze.valid?(from[0], from[1])
          direction <<= Maze::UNDER_SHIFT if @maze[from[0], from[1]] & direction == 0
          @paths[from] |= direction
        end

        opposite <<= Maze::UNDER_SHIFT if @maze[to[0], to[1]] & opposite == 0
        @paths[to] |= opposite

        return (opposite & Maze::UNDER == 0) ? :over : :under
      end

      return :over
    end

    def add_path(path)
      path.paths.each do |pt, value|
        @paths[pt] |= value
      end

      path.cells.each do |pt, value|
        @cells[pt] |= value
      end
    end

    def set?(point, how=:over)
      @cells[point] & (how == :over ? 1 : 2) != 0
    end

    def path?(point, direction)
      @paths[point] & direction != 0
    end
  end
end
