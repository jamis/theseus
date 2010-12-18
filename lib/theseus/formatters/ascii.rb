module Theseus
  module Formatters
    # ASCII formatters render a maze as ASCII art. The ASCII representation
    # is intended mostly to give you a "quick look" at the maze, and will
    # rarely suffice for showing more than an overview of the maze's shape.
    #
    # This is the abstract superclass of the ASCII formatters, and provides
    # helpers for writing to a textual "canvas".
    class ASCII
      # The width of the canvas. This corresponds to, but is not necessarily the
      # same as, the width of the maze.
      attr_reader :width

      # The height of the canvas. This corresponds to, but is not necessarily the
      # same as, the height of the maze.
      attr_reader :height

      # Create a new ASCII canvas with the given width and height. The canvas is
      # initially blank (set to whitespace).
      def initialize(width, height)
        @width, @height = width, height
        @chars = Array.new(height) { Array.new(width, " ") }
      end

      # Returns the character at the given coordinates.
      def [](x, y)
        @chars[y][x]
      end

      # Sets the character at the given coordinates.
      def []=(x, y, char)
        @chars[y][x] = char
      end

      # Returns the canvas as a multiline string, suitable for displaying.
      def to_s
        @chars.map { |row| row.join }.join("\n")
      end
    end
  end
end
