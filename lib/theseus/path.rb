module Theseus
  # The Path class is used to represent paths (and, generally, regions) within
  # a maze. Arbitrary metadata can be associated with these paths, as well.
  #
  # Although a Path can be instantiated directly, it is generally more convenient
  # (and less error-prone) to instantiate them via Maze#new_path.
  class Path
    # Represents the exit paths from each cell in the Path. This is a Hash of bitfields,
    # and should be treated as read-only.
    attr_reader :paths

    # Represents the cells within the Path. This is a Hash of bitfields, with bit 1
    # meaning the primary plane for the cell is set for this Path, and bit 2 meaning
    # the under plane for the cell is set.
    attr_reader :cells

    # Instantiates a new plane for the given +maze+ instance, and with the given +meta+
    # data. Initially, the path is empty.
    def initialize(maze, meta={})
      @maze = maze
      @paths = Hash.new(0)
      @cells = Hash.new(0)
      @meta = meta
    end

    # Returns the metadata for the given +key+.
    def [](key)
      @meta[key]
    end

    # Marks the given +point+ as occupied in this path. If +how+ is +:over+, the
    # point is set in the primary plane. Otherwise, it is set in the under plane.
    #
    # The +how+ parameter is usually used in conjunction with the return value of
    # the #link method:
    #
    #   how = path.link(from, to)
    #   path.set(to, how)
    def set(point, how=:over)
      @cells[point] |= (how == :over ? 1 : 2)
    end

    # Creates a link between the two given points. The points must be adjacent.
    # If the corresponding passage in the maze moves into the under plane as it
    # enters +to+, this method returns +:under+. Otherwise, it returns +:over+.
    #
    # If the two points are not adjacent, no link is created.
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

    # Adds all path and cell information from the parameter (which must be a
    # Path instance) to the current Path object. The metadata from the parameter
    # is not copied.
    def add_path(path)
      path.paths.each do |pt, value|
        @paths[pt] |= value
      end

      path.cells.each do |pt, value|
        @cells[pt] |= value
      end
    end
    
    # Returns true if the given point is occuped in the path, for the given plane.
    # If +how+ is +:over+, the primary plane is queried. Otherwise, the under
    # plane is queried.
    def set?(point, how=:over)
      @cells[point] & (how == :over ? 1 : 2) != 0
    end

    # Returns true if there is a path from the given point, in the given direction.
    def path?(point, direction)
      @paths[point] & direction != 0
    end
  end
end
