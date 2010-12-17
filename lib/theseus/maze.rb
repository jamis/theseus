require 'theseus/mask'
require 'theseus/path'

module Theseus
  # Theseus::Maze is an abstract class, intended to act solely as a superclass
  # for specific maze types. See Theseus::OrthogonalMaze for an example.
  class Maze

    # Each cell in the maze is a bitfield. The bits that are set indicate which
    # passages exist leading AWAY from this cell. Bits in the low byte (corresponding
    # to the PRIMARY bitmask) represent passages on the normal plane. Bits in the
    # high byte (corresponding to the UNDER bitmask) represent passages that are
    # passing under this cell.

    N  = 0x01 # North
    S  = 0x02 # South
    E  = 0x04 # East
    W  = 0x08 # West
    NW = 0x10 # Northwest
    NE = 0x20 # Northeast
    SW = 0x40 # Southwest
    SE = 0x80 # Southeast

    # bitmask identifying directional bits on the primary plane
    PRIMARY = 0x00FF

    # bitmask identifying directional bits under the primary plane
    UNDER   = 0xFF00

    # The size of the PRIMARY bitmask (e.g. how far to the left the
    # UNDER bitmask is shifted).
    UNDER_SHIFT = 8

    # The width of the maze (number of columns).
    #
    # In general, it is safest to use the #row_length method for a particular
    # row, since it is theoretically possible for a maze subclass to describe
    # a different width for each row.
    attr_reader :width

    # The height of the maze (number of rows).
    attr_reader :height

    # An integer between 0 and 100 (inclusive). 0 means passages will only
    # change direction when they encounter a barrier they cannot move through
    # (or under). 100 means that as passages are built, a new direction will
    # always be randomly chosen for each step of the algorithm.
    attr_reader :randomness

    # An integer between 0 and 100 (inclusive). 0 means passages will never
    # move over or under existing passages. 100 means whenever possible,
    # passages will move over or under existing passages. Note that not all
    # maze types support weaving.
    attr_reader :weave

    # An integer between 0 and 100 (inclusive), signifying the percentage
    # of deadends in the maze that will be extended in some direction until
    # they join with an existing passage. This will create loops in the
    # graph. Thus, 0 is a "perfect" maze (with no loops), and 100 is a
    # maze that is totally multiply-connected, with no dead-ends.
    attr_reader :braid

    # One of :none, :x, :y, or :xy, indicating which boundaries the maze
    # should wrap around. The default is :none, indicating no wrapping.
    # If :x, the maze will wrap around the left and right edges. If
    # :y, the maze will wrap around the top and bottom edges. If :xy, the
    # maze will wrap around both edges.
    attr_reader :wrap

    # A Theseus::Mask (or similar) instance, that is used by the algorithm to
    # determine which cells in the space are allowed. This lets you create
    # mazes that fill shapes, or flow around patterns.
    attr_reader :mask

    # One of :none, :x, :y, :xy, or :radial. Note that not all maze types
    # support symmetry. The :x symmetry means the maze will be mirrored
    # across the x axis. Similarly, :y symmetry means the maze will be
    # mirrored across the y axis. :xy symmetry causes the maze to be
    # mirrored across both axes, and :radial symmetry causes the maze to
    # be mirrored radially about the center of the maze.
    attr_reader :symmetry

    # A 2-tuple (array) indicating the x and y coordinates where the maze
    # should be entered. This is used primarly when generating the solution
    # to the maze, and generally defaults to the upper-left corner.
    attr_reader :entrance

    # A 2-tuple (array) indicating the x and y coordinates where the maze
    # should be exited. This is used primarly when generating the solution
    # to the maze, and generally defaults to the lower-right corner.
    attr_reader :exit

    # A short-hand method for creating a new maze object and causing it to
    # be generated, in one step. Returns the newly generated maze.
    def self.generate(options={})
      maze = new(width, height, options)
      maze.generate!
      return maze
    end

    # Creates and returns a new maze object. Note that the maze will _not_
    # be generated; the maze is initially blank.
    #
    # Many options are supported:
    #
    # [:width]       The number of columns in the maze. Note that different
    #                maze types count columns and rows differently; you'll
    #                want to see individual maze types for more info.
    # [:height]      The number of rows in the maze.
    # [:symmetry]    The symmetry to be used when generating the maze. This
    #                defaults to +:none+, but may also be +:x+ (to have the
    #                maze mirrored across the x-axis), +:y+ (to mirror the
    #                maze across the y-axis), +:xy+ (to mirror across both
    #                axes simultaneously), and +:radial+ (to mirror the maze
    #                radially about the center). Some symmetry types may
    #                result in loops being added to the maze, regardless of
    #                the braid value (see the +:braid+ parameter).
    #                (NOTE: not all maze types support symmetry equally.)
    # [:randomness]  An integer between 0 and 100 (inclusive) indicating how
    #                randomly the maze is generated. A 0 means that the maze
    #                passages will prefer to go straight whenever possible.
    #                A 100 means the passages will choose random directions
    #                as often as possible.
    # [:mask]        An instance of Theseus::Mask (or something that acts
    #                similarly). This can be used to constrain the maze so that
    #                it fills or avoids specific areas, so that shapes and
    #                patterns can be made.
    # [:weave]       An integer between 0 and 100 (inclusive) indicating how
    #                frequently passages move under or over other passages.
    #                A 0 means the passages will never move over/under other
    #                passages, while a 100 means they will do so as often
    #                as possible. (NOTE: not all maze types support weaving.)
    # [:braid]       An integer between 0 and 100 (inclusive) representing
    #                the percentage of dead-ends that should be removed after
    #                the maze has been generated. Dead-ends are removed by
    #                extending them in some direction until they join with
    #                another passage. This will introduce loops into the maze,
    #                making it "multiply-connected". A braid value of 0 will
    #                always result in a "perfect" maze (with no loops), while
    #                a value of 100 will result in a maze with no dead-ends.
    # [:wrap]        Indicates which edges of the maze should wrap around.
    #                +:x+ will cause the left and right edges to wrap, and
    #                +:y+ will cause the top and bottom edges to wrap. You
    #                can specify +:xy+ to wrap both left-to-right and
    #                top-to-bottom. The default is +:none+ (for no wrapping).
    # [:entrance]    A 2-tuple indicating from where the maze is entered.
    #                By default, the maze's entrance will be the upper-left-most
    #                point.
    # [:exit]        A 2-tuple indicating from where the maze is exited.
    #                By default, the maze's entrance will be the lower-right-most
    #                point.
    # [:prebuilt]    Sometimes, you may want the new maze to be considered to be
    #                generated, but not actually have anything generated into it.
    #                You can set the +:prebuilt+ parameter to +true+ in this case,
    #                allowing you to then set the contents of the maze by hand,
    #                using the #[]= method.
    def initialize(options={})
      @width = (options[:width] || 10).to_i
      @height = (options[:height] || 10).to_i

      @symmetry = (options[:symmetry] || :none).to_sym
      configure_symmetry

      @randomness = options[:randomness] || 100
      @mask = options[:mask] || TransparentMask.new
      @weave = options[:weave].to_i
      @braid = options[:braid].to_i
      @wrap = options[:wrap] || :none

      @cells = setup_grid or raise "expected #setup_grid to return the new grid"

      @entrance = options[:entrance] || default_entrance
      @exit = options[:exit] || default_exit

      loop do
        @y = rand(@cells.length)
        @x = rand(@cells[@y].length)
        break if valid?(@x, @y)
      end

      @tries = potential_exits_at(@x, @y).sort_by { rand }
      @stack = []

      @generated = options[:prebuilt]
    end

    # Generates the maze if it has not already been generated. This is
    # essentially the same as calling #step repeatedly. If a block is given,
    # it will be called after each step.
    def generate!
      return if generated?
      yield if block_given? while step
    end

    # Creates a new Theseus::Path object based on this maze instance. This can
    # be used to (for instance) create special areas of the maze or routes through
    # the maze that you want to color specially. The following demonstrates setting
    # a particular cell in the maze to a light-purple color:
    #
    #   path = maze.new_path(color: 0xff7fffff)
    #   path.set([5,5])
    #   maze.to(:png, paths: [path])
    def new_path(meta={})
      Path.new(self, meta)
    end

    # Instantiates and returns a new solver instance which encapsulates a
    # solution algorithm. The options may contain the following keys:
    #
    # [:type] This defaults to +:backtracker+ (for the Theseus::Solvers::Backtracker
    #         solver), but may also be set to +:astar+ (for the Theseus::Solvers::Astar
    #         solver).
    # [:a]    A 2-tuple (defaulting to #start) that says where in the maze the
    #         solution should begin.
    # [:b]    A 2-tuple (defaulting to #finish) that says where in the maze the
    #         solution should finish.
    #
    # The returned solver will not yet have generated the solution. Use
    # Theseus::Solvers::Base#solve or Theseus::Solvers::Base#step to generate the
    # solution.
    def new_solver(options={})
      type = options[:type] || :backtracker

      require "theseus/solvers/#{type}"
      klass = Theseus::Solvers.const_get(type.to_s.capitalize)

      a = options[:a] || start
      b = options[:b] || finish

      klass.new(self, a, b)
    end

    # Returns the solution for the maze as an array of 2-tuples, each indicating
    # a cell (in sequence) leading from the start to the finish.
    #
    # See #new_solver for a description of the supported options.
    def solve(options={})
      new_solver(options).solution
    end

    def [](x,y)
      @cells[y][x]
    end

    def []=(x,y,value)
      @cells[y][x] = value
    end

    def step
      return false if @generated

      if @deadends && @deadends.any?
        dead_end = @deadends.pop
        braid(dead_end[0], dead_end[1])
        
        @generated = @deadends.empty?
        return !@generated
      end

      direction = next_direction or return !@generated
      nx, ny = move(@x, @y, direction)

      apply_move_at(@x, @y, direction)

      # if (nx,ny) is already visited, then we're weaving (moving either over
      # or under the existing passage).
      nx, ny, direction = perform_weave(@x, @y, nx, ny, direction) if @cells[ny][nx] != 0

      apply_move_at(nx, ny, opposite(direction))

      @stack.push([@x, @y, @tries])
      @tries = potential_exits_at(nx, ny).sort_by { rand }
      @tries.push direction if @tries.include?(direction) unless rand(100) < @randomness
      @x, @y = nx, ny

      return true
    end

    def generated?
      @generated
    end

    def start
      adjacent_point(@entrance)
    end

    def finish
      adjacent_point(@exit)
    end

    def potential_exits_at(x, y)
      raise NotImplementedError, "subclasses must implement #potential_exits_at"
    end

    def wrap_x?
      @wrap == :x || @wrap == :xy
    end

    def wrap_y?
      @wrap == :y || @wrap == :xy
    end

    def valid?(x, y)
      return false if !wrap_y? && (y < 0 || y >= height)
      y %= height
      return false if !wrap_x? && (x < 0 || x >= row_length(y))
      x %= row_length(y)
      return @mask[x, y]
    end

    def move(x, y, direction)
      nx, ny = x + dx(direction), y + dy(direction)

      ny %= height if wrap_y?
      nx %= row_length(ny) if wrap_x? && ny > 0 && ny < height

      [nx, ny]
    end

    def dead_ends
      dead_ends = []

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          dead_ends << [x, y] if dead?(cell)
        end
      end

      dead_ends
    end

    def sparsify!
      dead_ends.each do |(x, y)|
        cell = @cells[y][x]
        direction = cell & PRIMARY
        nx, ny = move(x, y, direction)

        # if the cell includes UNDER codes, shifting it all UNDER_SHIFT bits to the right
        # will convert those UNDER codes to PRIMARY codes. Otherwise, it will
        # simply zero the cell, resulting in a blank spot.
        @cells[y][x] >>= UNDER_SHIFT

        # if it's a weave cell (that moves over or under another corridor),
        # nix it and move back one more, so we don't wind up with dead-ends
        # underneath another corridor.
        if @cells[ny][nx] & (opposite(direction) << UNDER_SHIFT) != 0
          @cells[ny][nx] &= ~((direction | opposite(direction)) << UNDER_SHIFT)
          nx, ny = move(nx, ny, direction)
        end

        @cells[ny][nx] &= ~opposite(direction)
      end
    end

    def opposite(direction)
      if direction & UNDER != 0
        opposite(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then S
        when S  then N
        when E  then W
        when W  then E
        when NE then SW
        when NW then SE
        when SE then NW
        when SW then NE
        end
      end
    end

    def hmirror(direction)
      if direction & UNDER != 0
        hmirror(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when E  then W
        when W  then E
        when NW then NE
        when NE then NW
        when SW then SE
        when SE then SW
        else direction
        end
      end
    end

    def vmirror(direction)
      if direction & UNDER != 0
        vmirror(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then S
        when S  then N
        when NE then SE
        when NW then SW
        when SE then NE
        when SW then NW
        else direction
        end
      end
    end

    # a 90-degree clockwise turn
    def clockwise(direction)
      if direction & UNDER != 0
        clockwise(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then E
        when E  then S
        when S  then W
        when W  then N
        when NW then NE
        when NE then SE
        when SE then SW
        when SW then NW
        end
      end
    end

    # a 90-degree counter-clockwise turn
    def counter_clockwise(direction)
      if direction & UNDER != 0
        counter_clockwise(direction >> UNDER_SHIFT) << UNDER_SHIFT
      else
        case direction
        when N  then W
        when W  then S
        when S  then E
        when E  then N
        when NW then SW
        when SW then SE
        when SE then NE
        when NE then NW
        end
      end
    end

    def dx(direction)
      case direction
      when E, NE, SE then 1
      when W, NW, SW then -1
      else 0
      end
    end

    def dy(direction)
      case direction
      when S, SE, SW then 1
      when N, NE, NW then -1
      else 0
      end
    end

    def row_length(row)
      @cells[row].length
    end

    def dead?(cell)
      raw = cell & PRIMARY
      raw == N || raw == S || raw == E || raw == W ||
        raw == NE || raw == NW || raw == SE || raw == SW
    end

    def add_opening_from(point)
      x, y = point
      if valid?(x, y)
        # nothing to be done
      else
        potential_exits_at(x, y).each do |direction|
          nx, ny = move(x, y, direction)
          if valid?(nx, ny)
            @cells[ny][nx] |= opposite(direction)
            return
          end
        end
      end
    end

    def adjacent_point(point)
      x, y = point
      if valid?(x, y)
        [x, y]
      else
        potential_exits_at(x, y).each do |direction|
          nx, ny = move(x, y, direction)
          return [nx, ny] if valid?(nx, ny)
        end
      end
    end

    # returns the direction of 'to' relative to 'from'. 'to' and 'from'
    # are both points (2-tuples).
    def relative_direction(from, to)
      if from[0] < to[0]
        if from[1] < to[1]
          SE
        elsif from[1] > to[1]
          NE
        else
          E
        end
      elsif from[0] > to[0]
        if from[1] < to[1]
          SW
        elsif from[1] > to[1]
          NW
        else
          W
        end
      elsif from[1] < to[1]
        S
      elsif from[1] > to[1]
        N
      else
        # same point!
        nil
      end
    end

    def type
      self.class.name[/::(.*?)Maze$/, 1]
    end

    def to(format, options={})
      case format
      when :ascii then
        require "theseus/formatters/ascii/#{type.downcase}"
        Formatters::ASCII.const_get(type).new(self, options)
      when :png then
        require "theseus/formatters/png/#{type.downcase}"
        Formatters::PNG.const_get(type).new(self, options).to_blob
      else
        raise ArgumentError, "unknown format: #{format.inspect}"
      end
    end

    def to_s(options={})
      to(:ascii, options).to_s
    end

    def inspect
      "#<#{self.class.name}:0x%X %dx%d %s>" % [
        object_id, @width, @height,
        generated? ? "generated" : "not generated"]
    end

    private

    def configure_symmetry
      if @symmetry != :none
        raise NotImplementedError, "only :none symmetry is implemented by default"
      end
    end

    def setup_grid
      Array.new(height) { Array.new(width, 0) }
    end

    def deadends_to_braid
      return [] if @braid.zero?

      ends = dead_ends

      count = ends.length * @braid / 100
      count = 1 if count < 1

      ends.sort_by { rand }[0,count]
    end

    def default_entrance
      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          return [x-1, y] if @mask[x, y]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    def default_exit
      @cells.reverse.each_with_index do |row, y|
        ry = @cells.length - y - 1
        row.reverse.each_with_index do |cell, x|
          rx = row.length - x - 1
          return [rx+1, ry] if @mask[rx, ry]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    def next_direction
      loop do
        direction = @tries.pop
        nx, ny = move(@x, @y, direction)

        if valid?(nx, ny) && (@cells[@y][@x] & (direction | (direction << UNDER_SHIFT)) == 0)
          if @cells[ny][nx] == 0
            return direction
          elsif !dead?(@cells[ny][nx]) && @weave > 0 && rand(100) < @weave
            # see if we can weave over/under the cell at (nx,ny)
            return direction if weave_allowed?(@x, @y, nx, ny, direction)
          end
        end

        while @tries.empty?
          if @stack.empty?
            finish!
            return nil
          else
            @x, @y, @tries = @stack.pop
          end
        end
      end
    end

    def apply_move_at(x, y, direction)
      if direction == :under
        @cells[y][x] <<= UNDER_SHIFT
      else
        @cells[y][x] |= direction
      end

      case @symmetry
      when :x      then move_symmetrically_in_x(x, y, direction)
      when :y      then move_symmetrically_in_y(x, y, direction)
      when :xy     then move_symmetrically_in_xy(x, y, direction)
      when :radial then move_symmetrically_radially(x, y, direction)
      end
    end

    def move_symmetrically_in_x(x, y, direction)
      row_width = @cells[y].length
      if direction == :under
        @cells[y][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[y][row_width - x - 1] |= hmirror(direction)
      end
    end

    def move_symmetrically_in_y(x, y, direction)
      if direction == :under
        @cells[@cells.length - y - 1][x] <<= UNDER_SHIFT
      else
        @cells[@cells.length - y - 1][x] |= vmirror(direction)
      end
    end

    def move_symmetrically_in_xy(x, y, direction)
      row_width = @cells[y].length
      if direction == :under
        @cells[y][row_width - x - 1] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][x] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[y][row_width - x - 1] |= hmirror(direction)
        @cells[@cells.length - y - 1][x] |= vmirror(direction)
        @cells[@cells.length - y - 1][row_width - x - 1] |= opposite(direction)
      end
    end

    def move_symmetrically_radially(x, y, direction)
      row_width = @cells[y].length
      if direction == :under
        @cells[@cells.length - x - 1][y] <<= UNDER_SHIFT
        @cells[x][row_width - y - 1] <<= UNDER_SHIFT
        @cells[@cells.length - y - 1][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[@cells.length - x - 1][y] |= counter_clockwise(direction)
        @cells[x][row_width - y - 1] |= clockwise(direction)
        @cells[@cells.length - y - 1][row_width - x - 1] |= opposite(direction)
      end
    end

    def finish!
      add_opening_from(@entrance)
      add_opening_from(@exit)

      @deadends = deadends_to_braid
      @generated = @deadends.empty?
    end

    # TODO: look for the direction that results in the longest loop.
    # might be kind of spendy, but worth trying, at least.
    def braid(x, y)
      return unless dead?(@cells[y][x])
      tries = potential_exits_at(x, y)
      [opposite(@cells[y][x]), *tries].each do |try|
        next if try == @cells[y][x]
        nx, ny = move(x, y, try)
        if valid?(nx, ny)
          opp = opposite(try)
          next if @cells[ny][nx] & (opp << UNDER_SHIFT) != 0
          @cells[y][x] |= try
          @cells[ny][nx] |= opp
          return
        end
      end
    end

    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction)
      nx2, ny2 = move(thru_x, thru_y, direction)
      return (@cells[thru_y][thru_x] & UNDER == 0) && valid?(nx2, ny2) && @cells[ny2][nx2] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction)
      if rand(2) == 0 # move under existing passage
        apply_move_at(to_x, to_y, direction << UNDER_SHIFT)
        apply_move_at(to_x, to_y, opposite(direction) << UNDER_SHIFT)
      else # move over existing passage
        apply_move_at(to_x, to_y, :under)
        apply_move_at(to_x, to_y, direction)
        apply_move_at(to_x, to_y, opposite(direction))
      end
      
      nx, ny = move(to_x, to_y, direction)
      [nx, ny, direction]
    end

  end
end
