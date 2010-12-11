require 'theseus/maze'

module Theseus
  class DeltaMaze < Maze
    def initialize(options={})
      super
      raise ArgumentError, "weaving is not supported for delta mazes" if @weave > 0
    end

    def points_up?(x, y)
      (x + y) % 2 == height % 2
    end

    def potential_exits_at(x, y)
      vert = points_up?(x, y) ? S : N
      [vert, vert, E, W] # vert twice, otherwise E/W is extra likely to be selected
    end

    def to_s
      str = ""

      @cells.each_with_index do |row, y|
        r1 = " "
        r2 = ""
        row.each_with_index do |cell, x|
          if points_up?(x, y)
            if cell & W == 0
              r1 << "/"
              r2 << "/"
            else
              r1 << " "
              r2 << "_"
            end
            r2 << ((cell & S == 0) ? "__" : "  ")
          else
            if cell & W == 0
              r1 << "\\"
              r2 << "\\"
            else
              r1 << " "
              r2 << "_"
            end
            r1 << "  "
          end
        end
        r1 << "\\"
        r2 << "\\"
        str << r1 << "\n" << r2 << "\n"
      end

      str
    end

    def to(format, options={})
      case format
      when :png then
        require 'theseus/formatters/delta/png'
        Formatters::Delta::PNG.new(self, options).to_blob
      else
        raise ArgumentError, "unknown format: #{format.inspect}"
      end
    end
  end
end
