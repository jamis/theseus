module Theseus
  module Formatters
    class ASCII
      attr_reader :width, :height

      def initialize(width, height)
        @width, @height = width, height
        @chars = Array.new(height) { Array.new(width, " ") }
      end

      def [](x, y)
        @chars[y][x]
      end

      def []=(x, y, char)
        @chars[y][x] = char
      end

      def to_s
        @chars.map { |row| row.join }.join("\n")
      end
    end
  end
end
