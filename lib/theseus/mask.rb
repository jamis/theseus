require 'chunky_png'

module Theseus
  class Mask
    def self.from_text(text)
      new(text.strip.split(/\n/).map { |line| line.split(//).map { |c| c == '.' } })
    end

    def self.from_png(file_name)
      image = ChunkyPNG::Image.from_file(file_name)
      grid = Array.new(image.height) { |y| Array.new(image.width) { |x| (image[x, y] & 0xff) == 0 } }
      new(grid)
    end

    attr_reader :height, :width

    def initialize(grid)
      @grid = grid
      @height = @grid.length
      @width = @grid.map { |row| row.length }.max
    end

    def [](x,y)
      @grid[y][x]
    end
  end

  class TriangleMask
    attr_reader :height, :width

    def initialize(height)
      @height = height
      @width = @height * 2 + 1
      @grid = Array.new(@height) do |y|
        run = y * 2 + 1
        from = @height - y
        to = from + run - 1
        Array.new(@width) do |x| 
          (x >= from && x <= to) ? true : false
        end
      end
    end

    def [](x,y)
      @grid[y][x]
    end
  end

  class TransparentMask
    attr_reader :width, :height

    def initialize(width=0, height=0)
      @width = width
      @height = height
    end

    def [](x,y)
      true
    end
  end
end
