require 'theseus/mask'
require 'theseus/solver'

module Theseus
  class Maze
    N  = 0x01
    S  = 0x02
    E  = 0x04
    W  = 0x08
    NW = 0x10
    NE = 0x20
    SW = 0x40
    SE = 0x80

    PRIMARY = 0x00FF
    UNDER   = 0xFF00

    UNDER_SHIFT = 8

    attr_reader :width
    attr_reader :height
    attr_reader :randomness
    attr_reader :weave
    attr_reader :braid
    attr_reader :mask
    attr_reader :symmetry
    attr_reader :entrance
    attr_reader :exit

    def self.generate(options={})
      maze = new(width, height, options)
      maze.generate!
      return maze
    end

    def initialize(options={})
      @width = (options[:width] || 10).to_i
      @height = (options[:height] || 10).to_i

      @symmetry = (options[:symmetry] || :none).to_sym
      configure_symmetry

      @randomness = options[:randomness] || 100
      @mask = options[:mask] || TransparentMask.new
      @weave = options[:weave].to_i
      @braid = options[:braid].to_i

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

    def generate!
      yield if block_given? while step
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
      nx, ny = @x + dx(direction), @y + dy(direction)

      apply_move_at(@x, @y, direction)

      # if (nx,ny) is already visited, then we're weaving (moving either over
      # or under the existing passage).
      if @cells[ny][nx] != 0
        if rand(2) == 0 # move under existing passage
          apply_move_at(nx, ny, direction << UNDER_SHIFT)
          apply_move_at(nx, ny, opposite(direction) << UNDER_SHIFT)
        else # move over existing passage
          apply_move_at(nx, ny, :under)
          apply_move_at(nx, ny, direction)
          apply_move_at(nx, ny, opposite(direction))
        end

        nx, ny = nx + dx(direction), ny + dy(direction)
      end

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

    def valid?(x, y)
      x >= 0 && y >= 0 && y < @cells.length && x < @cells[y].length && @mask[x, y]
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
        nx, ny = x + dx(direction), y + dy(direction)

        # if the cell includes UNDER codes, shifting it all UNDER_SHIFT bits to the right
        # will convert those UNDER codes to PRIMARY codes. Otherwise, it will
        # simply zero the cell, resulting in a blank spot.
        @cells[y][x] >>= UNDER_SHIFT

        # if it's a weave cell (that moves over or under another corridor),
        # nix it and move back one more, so we don't wind up with dead-ends
        # underneath another corridor.
        if @cells[ny][nx] & (opposite(direction) << UNDER_SHIFT) != 0
          @cells[ny][nx] &= ~((direction | opposite(direction)) << UNDER_SHIFT)
          nx, ny = nx + dx(direction), ny + dy(direction)
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
          nx, ny = x + dx(direction), y + dy(direction)
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
          nx, ny = x + dx(direction), y + dy(direction)
          return [nx, ny] if valid?(nx, ny)
        end
      end
    end

    def solve(a=start, b=finish)
      Solver.new(self, a, b).solution
    end

    def type
      self.class.name.sub(/Maze$/, "")
    end

    def to(format, options={})
      case format
      when :png then
        require "theseus/formatters/png/#{type.downcase}"
        Formatters::PNG.const_get(type).new(self, options).to_blob
      else
        raise ArgumentError, "unknown format: #{format.inspect}"
      end
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
        nx, ny = @x + dx(direction), @y + dy(direction)

        if valid?(nx, ny) && (@cells[@y][@x] & (direction | (direction << UNDER_SHIFT)) == 0)
          if @cells[ny][nx] == 0
            return direction
          elsif !dead?(@cells[ny][nx]) && @weave > 0 && rand(100) < @weave
            # see if we can weave over/under the cell at (nx,ny)
            nx2, ny2 = nx + dx(direction), ny + dy(direction)
            return direction if valid?(nx2, ny2) && @cells[ny2][nx2] == 0
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
        nx, ny = x + dx(try), y + dy(try)
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
