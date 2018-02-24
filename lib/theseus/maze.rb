require 'theseus/mask'
require 'theseus/path'
require 'theseus/algorithms/recursive_backtracker'

module Theseus
  # Theseus::Maze is an abstract class, intended to act solely as a superclass
  # for specific maze types. Subclasses include OrthogonalMaze, DeltaMaze,
  # SigmaMaze, and UpsilonMaze.
  #
  # Each cell in the maze is a bitfield. The bits that are set indicate which
  # passages exist leading AWAY from this cell. Bits in the low byte (corresponding
  # to the PRIMARY bitmask) represent passages on the normal plane. Bits
  # in the high byte (corresponding to the UNDER bitmask) represent passages
  # that are passing under this cell. (Under/over passages are controlled via the
  # #weave setting, and are not supported by all maze types.)
  class Maze
    N  = 0x01 # North
    S  = 0x02 # South
    E  = 0x04 # East
    W  = 0x08 # West
    NW = 0x10 # Northwest
    NE = 0x20 # Northeast
    SW = 0x40 # Southwest
    SE = 0x80 # Southeast

    # bitmask identifying directional bits on the primary plane
    PRIMARY  = 0x000000FF

    # bitmask identifying directional bits under the primary plane
    UNDER    = 0x0000FF00

    # bits reserved for use by individual algorithm implementations
    RESERVED = 0xFFFF0000

    # The size of the PRIMARY bitmask (e.g. how far to the left the
    # UNDER bitmask is shifted).
    UNDER_SHIFT = 8

    # The algorithm object used to generate this maze. Defaults to
    # an instance of Algorithms::RecursiveBacktracker.
    attr_reader :algorithm

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
    #
    # A maze that wraps in a single direction may be mapped onto a cylinder.
    # A maze that wraps in both x and y may be mapped onto a torus.
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
      new(options).generate!
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
    # [:algorithm]   The maze algorithm to use. This should be a class,
    #                adhering to the interface described by Theseus::Algorithms::Base.
    #                It defaults to Theseus::Algorithms::RecursiveBacktracker.
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
    #                patterns can be made. (NOTE: not all algorithms support
    #                masks.)
    # [:weave]       An integer between 0 and 100 (inclusive) indicating how
    #                frequently passages move under or over other passages.
    #                A 0 means the passages will never move over/under other
    #                passages, while a 100 means they will do so as often
    #                as possible. (NOTE: not all maze types and algorithms
    #                support weaving.)
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
    #                point. Note that it may lie outside the bounds of the maze
    #                by one cell (e.g. [-1,0]), indicating that the entrance
    #                is on the very edge of the maze.
    # [:exit]        A 2-tuple indicating from where the maze is exited.
    #                By default, the maze's entrance will be the lower-right-most
    #                point. Note that it may lie outside the bounds of the maze
    #                by one cell (e.g. [width,height-1]), indicating that the
    #                exit is on the very edge of the maze.
    # [:prebuilt]    Sometimes, you may want the new maze to be considered to be
    #                generated, but not actually have anything generated into it.
    #                You can set the +:prebuilt+ parameter to +true+ in this case,
    #                allowing you to then set the contents of the maze by hand,
    #                using the #[]= method.
    def initialize(options={})
      @deadends = nil

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

      algorithm_class = options[:algorithm] || Algorithms::RecursiveBacktracker
      @algorithm = algorithm_class.new(self, options)

      @generated = options[:prebuilt]
    end

    # Generates the maze if it has not already been generated. This is
    # essentially the same as calling #step repeatedly. If a block is given,
    # it will be called after each step.
    def generate!
      yield if block_given? while step unless generated?
      self
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

    # Returns the bitfield for the cell at the given (+x+,+y+) coordinate.
    def [](x,y)
      @cells[y][x]
    end

    # Sets the bitfield for the cell at the given (+x+,+y+) coordinate.
    def []=(x,y,value)
      @cells[y][x] = value
    end

    # Completes a single iteration of the maze generation algorithm. Returns
    # +false+ if the method should not be called again (e.g., the maze has
    # been completed), and +true+ otherwise.
    def step
      return false if @generated

      if @deadends && @deadends.any?
        dead_end = @deadends.pop
        braid_cell(dead_end[0], dead_end[1])

        @generated = @deadends.empty?
        return !@generated
      end

      if @algorithm.step
        return true
      else
        return finish!
      end
    end

    # Returns +true+ if the maze has been generated.
    def generated?
      @generated
    end

    # Since #entrance may be external to the maze, #start returns the cell adjacent to
    # #entrance that lies within the maze. If #entrance is already internal to the
    # maze, this method returns #entrance. If #entrance is _not_ adjacent to any
    # internal cell, this method returns +nil+.
    def start
      adjacent_point(@entrance)
    end

    # Since #exit may be external to the maze, #finish returns the cell adjacent to
    # #exit that lies within the maze. If #exit is already internal to the
    # maze, this method returns #exit. If #exit is _not_ adjacent to any
    # internal cell, this method returns +nil+.
    def finish
      adjacent_point(@exit)
    end

    # Returns an array of the possible exits for the cell at the given coordinates.
    # Note that this does not take into account boundary conditions: a move in any
    # of the returned directions may not actually be valid, and should be verified
    # before being applied.
    #
    # This is used primarily by subclasses to allow for different shaped cells
    # (e.g. hexagonal cells for SigmaMaze, octagonal cells for UpsilonMaze).
    def potential_exits_at(x, y)
      raise NotImplementedError, "subclasses must implement #potential_exits_at"
    end

    # Returns true if the maze may be wrapped in the x direction (left-to-right).
    def wrap_x?
      @wrap == :x || @wrap == :xy
    end

    # Returns true if the maze may be wrapped in the y direction (top-to-bottom).
    def wrap_y?
      @wrap == :y || @wrap == :xy
    end

    # Returns true if the given coordinates are valid within the maze. This will
    # be the case if:
    #
    # 1. The coordinates lie within the maze's bounds, and
    # 2. The current mask for the maze does not restrict the location.
    #
    # If the maze wraps in x, the x coordinate is unconstrained and will be
    # mapped (via modulo) to the bounds. Similarly, if the maze wraps in y,
    # the y coordinate will be unconstrained.
    def valid?(x, y)
      return false if !wrap_y? && (y < 0 || y >= height)
      y %= height
      return false if !wrap_x? && (x < 0 || x >= row_length(y))
      x %= row_length(y)
      return @mask[x, y]
    end

    # Moves the given (+x+,+y+) coordinates a single step in the given
    # +direction+. If wrapping in either x or y is active, the result will
    # be mapped to the maze's current bounds via modulo arithmetic. The
    # resulting coordinates are returned as a 2-tuple.
    #
    # Example:
    #
    #   x2, y2 = maze.move(x, y, Maze::W)
    def move(x, y, direction)
      nx, ny = x + dx(direction), y + dy(direction)

      ny %= height if wrap_y?
      nx %= row_length(ny) if wrap_x? && ny > 0 && ny < height

      [nx, ny]
    end

    # Returns a array of all dead-ends in the maze. Each element of the array
    # is a 2-tuple containing the coordinates of a dead-end.
    def dead_ends
      dead_ends = []

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          dead_ends << [x, y] if dead?(cell)
        end
      end

      dead_ends
    end

    # Removes one cell from all dead-ends in the maze. Each call to this method
    # removes another level of dead-ends, making the maze increasingly sparse.
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

    # Returns the direction opposite to the given +direction+. This will work
    # even if the +direction+ value is in the UNDER bitmask.
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

    # Returns the direction that is the horizontal mirror to the given +direction+.
    # This will work even if the +direction+ value is in the UNDER bitmask.
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

    # Returns the direction that is the vertical mirror to the given +direction+.
    # This will work even if the +direction+ value is in the UNDER bitmask.
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

    # Returns the direction that results by rotating the given +direction+
    # 90 degrees in the clockwise direction. This will work even if the +direction+
    # value is in the UNDER bitmask.
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

    # Returns the direction that results by rotating the given +direction+
    # 90 degrees in the counter-clockwise direction. This will work even if
    # the +direction+ value is in the UNDER bitmask.
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

    # Returns the change in x implied by the given +direction+.
    def dx(direction)
      case direction
      when E, NE, SE then 1
      when W, NW, SW then -1
      else 0
      end
    end

    # Returns the change in y implied by the given +direction+.
    def dy(direction)
      case direction
      when S, SE, SW then 1
      when N, NE, NW then -1
      else 0
      end
    end

    # Returns the number of cells in the given row. This is generally safer
    # than relying the #width method, since it is theoretically possible for
    # a maze to have a different number of cells for each of its rows.
    def row_length(row)
      @cells[row].length
    end

    # Returns +true+ if the given cell is a dead-end. This considers only
    # passages on the PRIMARY plane (the UNDER bits are ignored, because the
    # current algorithm for generating mazes will never result in a dead-end
    # that is underneath another passage).
    def dead?(cell)
      raw = cell & PRIMARY
      raw == N || raw == S || raw == E || raw == W ||
        raw == NE || raw == NW || raw == SE || raw == SW
    end

    # If +point+ is already located at a valid point within the maze, this
    # does nothing. Otherwise, it examines the potential exits from the
    # given point and looks for the first one that leads immediately to a
    # valid point internal to the maze. When it finds one, it adds a passage
    # to that cell leading to +point+. If no such adjacent cell exists, this
    # method silently does nothing.
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

    # If +point+ is already located at a valid point withint he maze, this
    # simply returns +point+. Otherwise, it examines the potential exits
    # from the given point and looks for the first one that leads immediately
    # to a valid point internal to the maze. When it finds one, it returns
    # that point. If no such point exists, it returns +nil+.
    def adjacent_point(point)
      x, y = point
      if valid?(x, y)
        point
      else
        potential_exits_at(x, y).each do |direction|
          nx, ny = move(x, y, direction)
          return [nx, ny] if valid?(nx, ny)
        end
      end
    end

    # Returns the direction of +to+ relative to +from+. +to+ and +from+
    # are both points (2-tuples).
    def relative_direction(from, to)
      # first, look for the case where the maze wraps, and from and to
      # are on opposite sites of the grid.
      if wrap_x? && from[1] == to[1] && (from[0] == 0 || to[0] == 0) && (from[0] == @width-1 || to[0] == @width-1)
        if from[0] < to[0]
          W
        else
          E
        end
      elsif wrap_y? && from[0] == to[0] && (from[1] == 0 || to[1] == 0) && (from[1] == @height-1 || to[1] == @height-1)
        if from[1] < to[1]
          N
        else
          S
        end
      elsif from[0] < to[0]
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

    # Applies a move in the given direction to the cell at (x,y). The +direction+
    # parameter may also be :under, in which case the cell is left-shifted so as
    # to move the existing passages to the UNDER plane.
    #
    # This method also handles the application of symmetrical moves, in the case
    # where #symmetry has been specified.
    #
    # You'll generally never call this method directly, except to construct grids
    # yourself.
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

    # Returns the type of the maze as a string. OrthogonalMaze, for
    # instance, is reported as "orthogonal".
    def type
      self.class.name[/::(.*?)Maze$/, 1]
    end

    # Returns the maze rendered to a particular format. Supported
    # formats are currently :ascii and :png. The +options+ hash is passed
    # through to the formatter.
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

    # Returns the maze rendered to a string.
    def to_s(options={})
      to(:ascii, options).to_s
    end

    def inspect # :nodoc:
      "#<#{self.class.name}:0x%X %dx%d %s>" % [
        object_id, @width, @height,
        generated? ? "generated" : "not generated"]
    end

    # Returns +true+ if a weave may be applied at (thru_x,thru_y) when moving
    # from (from_x,from_y) in +direction+. This will be true if the thru cell
    # does not already have anything in its UNDER plane, and if the cell
    # on the far side of thru is valid and blank.
    #
    # Subclasses may need to override this method if special interpretations
    # for +direction+ need to be considered (see SigmaMaze).
    def weave_allowed?(from_x, from_y, thru_x, thru_y, direction) #:nodoc:
      nx2, ny2 = move(thru_x, thru_y, direction)
      return (@cells[thru_y][thru_x] & UNDER == 0) && valid?(nx2, ny2) && @cells[ny2][nx2] == 0
    end

    def perform_weave(from_x, from_y, to_x, to_y, direction) #:nodoc:
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

    private

    # Not all maze types support symmetry. If a subclass supports any of the
    # symmetry types (or wants to implement its own), it should override this
    # method.
    def configure_symmetry #:nodoc:
      if @symmetry != :none
        raise NotImplementedError, "only :none symmetry is implemented by default"
      end
    end

    # The default grid should suffice for most maze types, but if a subclass
    # wants a custom grid, it must override this method. Note that the method
    # MUST always return an Array of rows, with each row being an Array of cells.
    def setup_grid #:nodoc:
      Array.new(height) { Array.new(width, 0) }
    end

    # Returns an array of deadends that ought to be braided (removed), based on
    # the value of the #braid setting.
    def deadends_to_braid #:nodoc:
      return [] if @braid.zero?

      ends = dead_ends

      count = ends.length * @braid / 100
      count = 1 if count < 1

      ends.shuffle[0,count]
    end

    # Calculate the default entrance, by looking for the upper-leftmost point.
    def default_entrance #:nodoc:
      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          return [x-1, y] if @mask[x, y]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    # Calculate the default exit, by looking for the lower-rightmost point.
    def default_exit #:nodoc:
      @cells.reverse.each_with_index do |row, y|
        ry = @cells.length - y - 1
        row.reverse.each_with_index do |cell, x|
          rx = row.length - x - 1
          return [rx+1, ry] if @mask[rx, ry]
        end
      end
      [0, 0] # if every cell is masked, then 0,0 is as good as any!
    end

    def move_symmetrically_in_x(x, y, direction) #:nodoc:
      row_width = @cells[y].length
      if direction == :under
        @cells[y][row_width - x - 1] <<= UNDER_SHIFT
      else
        @cells[y][row_width - x - 1] |= hmirror(direction)
      end
    end

    def move_symmetrically_in_y(x, y, direction) #:nodoc:
      if direction == :under
        @cells[@cells.length - y - 1][x] <<= UNDER_SHIFT
      else
        @cells[@cells.length - y - 1][x] |= vmirror(direction)
      end
    end

    def move_symmetrically_in_xy(x, y, direction) #:nodoc:
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

    def move_symmetrically_radially(x, y, direction) #:nodoc:
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

    # Finishes the generation of the maze by adding openings for the entrance
    # and exit, and determing which dead-ends to braid (if any).
    def finish! #:nodoc:
      add_opening_from(@entrance)
      add_opening_from(@exit)

      @deadends = deadends_to_braid
      @generated = @deadends.empty?

      return !@generated
    end

    # If (x,y) is not a dead-end, this does nothing. Otherwise, it extends the
    # dead-end in some direction until it joins with another passage.
    #
    # TODO: look for the direction that results in the longest loop.
    # might be kind of spendy, but worth trying, at least.
    def braid_cell(x, y) #:nodoc:
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

  end
end
