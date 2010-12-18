require 'theseus/maze'

module Theseus
  # An orthogonal maze is one in which the field is tesselated into squares. This is
  # probably the type of maze that most people think of, when they think of mazes.
  #
  # The orthogonal maze implementation in Theseus is the most complete, supporting
  # weaving as well as all four symmetry types. You can even convert any "perfect"
  # (no loops) orthogonal maze to a "unicursal" maze. (Unicursal means "one course",
  # and refers to a maze that has no junctions, only a single path that takes you
  # through every cell in the maze exactly once.)
  #
  #   maze = Theseus::OrthogonalMaze.generate(width: 10)
  #   puts maze
  class OrthogonalMaze < Maze
    def potential_exits_at(x, y) #:nodoc:
      [N, S, E, W]
    end

    # Extends Maze#finish! to make sure symmetrical mazes are properly closed.
    #--
    # Eventually, this would be good to generalize somehow, and make available to
    # the other maze types.
    #++
    def finish! #:nodoc:
      # for symmetrical mazes, if the size of the maze in the direction of reflection is
      # even, then we have two distinct halves that need to be joined in order for the
      # maze to be fully connected.

      available_width, available_height = @width, @height

      case @symmetry
      when :x then
        available_width = available_width / 2
      when :y then
        available_height = available_height / 2
      when :xy, :radial then 
        available_width = available_width / 2
        available_height = available_height / 2
      end

      connector = lambda do |x, y, ix, iy, dir|
        start_x, start_y = x, y
        while @cells[y][x] == 0
          y = (y + iy) % available_height
          x = (x + ix) % available_width
          break if start_x == x || start_y == y
        end

        if @cells[y][x] == 0
          warn "maze cannot be fully connected"
          nil
        else
          @cells[y][x] |= dir
          nx, ny = move(x, y, dir)
          @cells[ny][nx] |= opposite(dir)
          [x,y]
        end
      end

      even = lambda { |x| x % 2 == 0 }

      case @symmetry
        when :x then
          connector[available_width-1, rand(available_height), 0, 1, E] if even[@width]
        when :y then
          connector[rand(available_width), available_height-1, 1, 0, S] if even[@height]
        when :xy then
          if even[@width]
            x, y = connector[available_width-1, rand(available_height), 0, 1, E]
            @cells[@height-y-1][x] |= E
            @cells[@height-y-1][x+1] |= W
          end

          if even[@height]
            x, y = connector[rand(available_width), available_height-1, 1, 0, S]
            @cells[y][@width-x-1] |= S
            @cells[y+1][@width-x-1] |= N
          end
        when :radial then
          if even[@width]
            @cells[available_height-1][available_width-1] |= E | S
            @cells[available_height-1][available_width] |= W | S
            @cells[available_height][available_width-1] |= E | N
            @cells[available_height][available_width] |= W | N
          end
      end

      super
    end

    # Takes the current orthogonal maze and converts it into a unicursal maze. A unicursal
    # maze is one with only a single path, and no dead-ends or junctions. Such mazes are
    # more properly called "labyrinths". Note that although this method will always return
    # a new OrthogonalMaze instance, it is not guaranteed to be a valid maze unless the
    # current maze is "perfect" (not braided, containing no loops).
    #
    # The resulting unicursal maze will be twice as wide and twice as high as the original
    # maze.
    #
    # The +options+ hash can be used to specify the <code>:entrance</code> and
    # <code>:exit</code> points for the resulting maze. Currently, both the entrance and
    # the exit must be adjacent.
    #
    # The process of converting an orthogonal maze to a unicursal maze is straightforward;
    # take the maze, and divide all passages in half down the middle, making two passages.
    # Dead-ends become a u-turn, etc. This is why the maze increases in size.
    def to_unicursal(options={})
      unicursal = OrthogonalMaze.new(options.merge(width: @width*2, height: @height*2, prebuilt: true))

      set = lambda do |x, y, direction, *recip|
        nx, ny = move(x, y, direction)
        unicursal[x,y] |= direction
        unicursal[nx, ny] |= opposite(direction) if recip[0]
      end

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          x2 = x * 2
          y2 = y * 2

          if cell & N != 0
            set[x2, y2, N]
            set[x2+1, y2, N]
            set[x2, y2+1, N, true] if cell & W == 0
            set[x2+1, y2+1, N, true] if cell & E == 0
            set[x2, y2+1, E, true] if (cell & PRIMARY) == N
          end

          if cell & S != 0
            set[x2, y2+1, S]
            set[x2+1, y2+1, S]
            set[x2, y2, S, true] if cell & W == 0
            set[x2+1, y2, S, true] if cell & E == 0
            set[x2, y2, E, true] if (cell & PRIMARY) == S
          end

          if cell & W != 0
            set[x2, y2, W]
            set[x2, y2+1, W]
            set[x2+1, y2, W, true] if cell & N == 0
            set[x2+1, y2+1, W, true] if cell & S == 0
            set[x2+1, y2, S, true] if (cell & PRIMARY) == W
          end

          if cell & E != 0
            set[x2+1, y2, E]
            set[x2+1, y2+1, E]
            set[x2, y2, E, true] if cell & N == 0
            set[x2, y2+1, E, true] if cell & S == 0
            set[x2, y2, S, true] if (cell & PRIMARY) == E
          end

          if cell & (N << UNDER_SHIFT) != 0
            unicursal[x2, y2] |= (N | S) << UNDER_SHIFT
            unicursal[x2+1, y2] |= (N | S) << UNDER_SHIFT
            unicursal[x2, y2+1] |= (N | S) << UNDER_SHIFT
            unicursal[x2+1, y2+1] |= (N | S) << UNDER_SHIFT
          elsif cell & (W << UNDER_SHIFT) != 0
            unicursal[x2, y2] |= (E | W) << UNDER_SHIFT
            unicursal[x2+1, y2] |= (E | W) << UNDER_SHIFT
            unicursal[x2, y2+1] |= (E | W) << UNDER_SHIFT
            unicursal[x2+1, y2+1] |= (E | W) << UNDER_SHIFT
          end
        end
      end

      enter_at = unicursal.adjacent_point(unicursal.entrance)
      exit_at = unicursal.adjacent_point(unicursal.exit)

      if enter_at && exit_at
        unicursal.add_opening_from(unicursal.entrance)
        unicursal.add_opening_from(unicursal.exit)

        if enter_at[0] < exit_at[0]
          unicursal[enter_at[0], enter_at[1]] &= ~E
          unicursal[enter_at[0]+1, enter_at[1]] &= ~W
        elsif enter_at[1] < exit_at[1]
          unicursal[enter_at[0], enter_at[1]] &= ~S
          unicursal[enter_at[0], enter_at[1]+1] &= ~N
        end
      end

      return unicursal
    end

    private

    def configure_symmetry #:nodoc:
      if @symmetry == :radial && @width != @height
        raise ArgumentError, "radial symmetrial is only possible for mazes where width == height"
      end
    end
  end
end
