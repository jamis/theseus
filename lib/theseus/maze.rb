# encoding: UTF-8

require 'theseus/mask'
require 'theseus/solver'

module Theseus
  class Maze
    NORTH = 0x01
    SOUTH = 0x02
    EAST  = 0x04
    WEST  = 0x08

    PRIMARY = 0x000F
    UNDER   = 0xF000

    DIRECTIONS = [NORTH, SOUTH, EAST, WEST]

    attr_reader :width, :height
    attr_reader :entrance, :exit

    def self.generate(width, height, options={})
      maze = new(width, height, options)
      maze.generate!
      return maze
    end

    def initialize(width, height, options={})
      @width = width
      @height = height
      @entrance = options[:entrance] || [-1,0]
      @exit = options[:exit] || [@width,@height-1]
      @randomness = options[:randomness] || 100
      @mask = options[:mask] || TransparentMask.new
      @weave = options[:weave] || 0
      @cells = Array.new(height) { Array.new(width, 0) }
      loop do
        @x = rand(@width)
        @y = rand(@height)
        break if @mask[@x, @y]
      end
      @tries = new_tries
      @stack = []
      @generated = false
    end

    def new_tries
      DIRECTIONS.sort_by { rand }
    end

    def [](x,y)
      @cells[y][x]
    end

    def []=(x,y,value)
      @cells[y][x] = value
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

    def dx(direction)
      case direction
      when EAST then 1
      when WEST then -1
      else 0
      end
    end

    def dy(direction)
      case direction
      when SOUTH then 1
      when NORTH then -1
      else 0
      end
    end

    def opposite(direction)
      case direction
      when NORTH then SOUTH
      when SOUTH then NORTH
      when EAST  then WEST
      when WEST  then EAST
      end
    end

    def d2s(direction)
      case direction
      when NORTH then "north"
      when SOUTH then "south"
      when EAST  then "west"
      when WEST  then "east"
      end
    end

    def in_bounds?(x, y)
      x >= 0 && y >= 0 && x < @width && y < @height && @mask[x, y]
    end

    def next_direction
      loop do
        direction = @tries.pop
        nx, ny = @x + dx(direction), @y + dy(direction)

        if in_bounds?(nx, ny) && (@cells[@y][@x] & direction == 0)
          if @cells[ny][nx] == 0
            return direction
          elsif !DIRECTIONS.include?(@cells[nx][ny]) && @weave > 0 && (@weave == 100 || rand(100) < @weave)
            # see if we can weave over/under the cell at (nx,ny)
            nx2, ny2 = nx + dx(direction), ny + dy(direction)
            return direction if in_bounds?(nx2, ny2) && @cells[ny2][nx2] == 0
          end
        end

        while @tries.empty?
          if @stack.empty?
            add_opening_from(@entrance)
            add_opening_from(@exit)
            @generated = true
            return nil
          else
            @x, @y, @tries = @stack.pop
          end
        end
      end
    end

    def step
      return nil if @generated

      direction = next_direction or return nil
      nx, ny = @x + dx(direction), @y + dy(direction)

      @cells[@y][@x] |= direction

      # if (nx,ny) is already visited, then we're weaving (moving either over
      # or under the existing passage).
      if @cells[ny][nx] != 0
        if rand(2) == 0 # move under existing passage
          @cells[ny][nx] |= (direction | opposite(direction)) << 4
        else # move over existing passage
          @cells[ny][nx] <<= 4
          @cells[ny][nx] |= direction | opposite(direction)
        end

        nx, ny = nx + dx(direction), ny + dy(direction)
      end

      @cells[ny][nx] |= opposite(direction)

      @stack.push([@x, @y, @tries])
      @tries = new_tries
      @tries.push direction unless rand(100) < @randomness
      @x, @y = nx, ny

      return [nx, ny]
    end

    def generate!
      while (cell = step)
        yield cell if block_given?
      end
    end

    def sparsify!
      dead_ends = []

      @cells.each_with_index do |row, y|
        row.each_with_index do |cell, x|
          raw = cell & PRIMARY
          if raw == NORTH || raw == SOUTH || raw == EAST || raw == WEST
            dead_ends << [x, y]
          end
        end
      end

      dead_ends.each do |(x, y)|
        cell = @cells[y][x]
        direction = cell & PRIMARY
        nx, ny = x + dx(direction), y + dy(direction)

        # if the cell includes UNDER codes, shifting it all 4 bits to the right
        # will convert those UNDER codes to PRIMARY codes. Otherwise, it will
        # simply zero the cell, resulting in a blank spot.
        @cells[y][x] >>= 4

        # if it's a weave cell (that moves over or under another corridor),
        # nix it and move back one more, so we don't wind up with dead-ends
        # underneath another corridor.
        if @cells[ny][nx] & (opposite(direction) << 4) != 0
          @cells[ny][nx] &= ~((direction | opposite(direction)) << 4)
          nx, ny = nx + dx(direction), ny + dy(direction)
        end

        @cells[ny][nx] &= ~opposite(direction)
      end
    end

    def solve(a=start, b=finish)
      Solver.new(self, a, b).solution
    end

    def inspect
      "#<Maze:0x%X %dx%d %s>" % [
        object_id, @width, @height,
        generated? ? "generated" : "not generated"]
    end

    def to_s(mode=nil)
      case mode
      when nil then to_simple_ascii
      when :utf8_lines then to_utf8_lines
      when :utf8_halls then to_utf8_halls
      else raise ArgumentError, "unknown mode #{mode.inspect}"
      end
    end

    def to(format, options={})
      case format
      when :png then
        require 'theseus/formatters/png'
        Formatters::PNG.new(self, options).to_blob
      else
        raise ArgumentError, "unknown format: #{format.inspect}"
      end
    end

    SIMPLE_SPRITES = [
      ["   ", "   "], # " "
      ["| |", "+-+"], # "╵"
      ["+-+", "| |"], # "╷"
      ["| |", "| |"], # "│",
      ["+--", "+--"], # "╶" 
      ["| .", "+--"], # "└" 
      ["+--", "| ."], # "┌"
      ["| .", "| ."], # "├" 
      ["--+", "--+"], # "╴"
      [". |", "--+"], # "┘"
      ["--+", ". |"], # "┐"
      [". |", ". |"], # "┤"
      ["---", "---"], # "─"
      [". .", "---"], # "┴"
      ["---", ". ."], # "┬"
      [". .", ". ."]  # "┼"
    ]

    UTF8_SPRITES = [
      ["   ", "   "], # " "
      ["│ │", "└─┘"], # "╵"
      ["┌─┐", "│ │"], # "╷"
      ["│ │", "│ │"], # "│",
      ["┌──", "└──"], # "╶" 
      ["│ └", "└──"], # "└" 
      ["┌──", "│ ┌"], # "┌"
      ["│ └", "│ ┌"], # "├" 
      ["──┐", "──┘"], # "╴"
      ["┘ │", "──┘"], # "┘"
      ["──┐", "┐ │"], # "┐"
      ["┘ │", "┐ │"], # "┤"
      ["───", "───"], # "─"
      ["┘ └", "───"], # "┴"
      ["───", "┐ ┌"], # "┬"
      ["┘ └", "┐ ┌"]  # "┼"
    ]

    UTF8_LINES = [" ", "╵", "╷", "│", "╶", "└", "┌", "├", "╴", "┘", "┐", "┤", "─", "┴", "┬", "┼"]

    def render_with_sprites(sprites)
      str = ""
      @cells.each do |row|
        r1, r2 = "", ""
        row.each do |cell|
          sprite = sprites[cell & PRIMARY]
          r1 << sprite[0]
          r2 << sprite[1]
        end
        str << r1 << "\n"
        str << r2 << "\n"
      end
      str
    end

    def to_simple_ascii
      render_with_sprites(SIMPLE_SPRITES)
    end

    def to_utf8_halls
      render_with_sprites(UTF8_SPRITES)
    end

    def to_utf8_lines
      str = ""
      @cells.each do |row|
        row.each do |cell|
          str << UTF8_LINES[cell & PRIMARY]
        end
        str << "\n"
      end
      str
    end

    def add_opening_from(point)
      x, y = point
      if in_bounds?(x, y)
        # nothing to be done
      elsif in_bounds?(x-1, y)
        @cells[y][x-1] |= EAST
      elsif in_bounds?(x+1, y)
        @cells[y][x+1] |= WEST
      elsif in_bounds?(x, y-1)
        @cells[y-1][x] |= SOUTH
      elsif in_bounds?(x, y+1)
        @cells[y+1][x] |= NORTH
      end
    end

    def adjacent_point(point)
      x, y = point
      if in_bounds?(x, y)
        [x, y]
      elsif in_bounds?(x-1, y)
        [x-1, y]
      elsif in_bounds?(x+1, y)
        [x+1, y]
      elsif in_bounds?(x, y-1)
        [x, y-1]
      elsif in_bounds?(x, y+1)
        [x, y+1]
      end
    end
  end
end
