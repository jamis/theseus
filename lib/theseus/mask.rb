require 'chunky_png'

module Theseus
  # A "mask" is, conceptually, a grid of true/false values that corresponds,
  # one-to-one, with the cells of a maze object. For every mask cell that is true,
  # the corresponding cell in a maze may contain passages. For every mask cell that
  # is false, the corresponding maze cell must be blank.
  #
  # Any object may be used as a mask as long as it responds to #height, #width, and
  # #[].
  class Mask
    # Given a string, treat each line as rows and each character as a cell. Every
    # period character (".") will be mapped to +true+, and everything else to +false+.
    # This lets you define simple masks as ASCII art:
    #
    #   mask_string = <<MASK
    #   ..........
    #   .X....XXX.
    #   ..X....XX.
    #   ...X....X.
    #   ....X.....
    #   .....X....
    #   .X....X...
    #   .XX....X..
    #   .XXX....X.
    #   ..........
    #   MASK
    #
    #   mask = Theseus::Mask.from_text(mask_string)
    #
    def self.from_text(text)
      new(text.strip.split(/\n/).map { |line| line.split(//).map { |c| c == '.' } })
    end

    # Given a PNG file with the given +file_name+, read the file and create a new
    # mask where transparent pixels will be considered +true+, and all others +false+.
    # Note that a pixel with any transparency at all will be considered +true+.
    #
    # The resulting mask will have the same dimensions as the image file.
    def self.from_png(file_name)
      image = ChunkyPNG::Image.from_file(file_name)
      grid = Array.new(image.height) { |y| Array.new(image.width) { |x| (image[x, y] & 0xff) == 0 } }
      new(grid)
    end

    # The number of rows in the mask.
    attr_reader :height

    # the length of the longest row in the mask.
    attr_reader :width

    # Instantiate a new mask from the given grid, which must be an Array of rows, and each
    # row must be an Array of true/false values for each column in the row.
    def initialize(grid)
      @grid = grid
      @height = @grid.length
      @width = @grid.map { |row| row.length }.max
    end

    # Returns the +true+/+false+ value for the corresponding cell in the grid.
    def [](x,y)
      @grid[y][x]
    end
  end

  # This is a specialized mask, intended for use with DeltaMaze instances (although
  # it will work with any maze). This lets you easily create triangular delta mazes.
  #
  #   mask = Theseus::TriangleMask.new(10)
  #   maze = Theseus::DeltaMaze.generate(mask: mask)
  class TriangleMask
    attr_reader :height, :width

    # Returns a new TriangleMask instance with the given height. The width will
    # always be <code>2h+1</code> (where +h+ is the height).
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

    # Returns the +true+/+false+ value for the corresponding cell in the grid.
    def [](x,y)
      @grid[y][x]
    end
  end

  # This is the default mask used by a maze when an explicit mask is not given.
  # It simply reports every cell as available.
  #
  #   mask = Theseus::TransparentMask.new(20, 20)
  #   maze = Theseus::OrthogonalMaze.new(mask: mask)
  class TransparentMask
    attr_reader :width, :height

    def initialize(width=0, height=0)
      @width = width
      @height = height
    end

    # Always returns +true+.
    def [](x,y)
      true
    end
  end
end
