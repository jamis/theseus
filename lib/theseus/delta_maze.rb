require 'theseus/maze'

module Theseus
  class DeltaMaze < Maze
    def potential_exits_at(x, y)
      vert = ((x + y) % 2 == 0) ? S : N
      [vert, vert, E, W] # vert twice, otherwise E/W is extra likely to be selected
    end

    def to_s
      str = ""

      @cells.each_with_index do |row, y|
        r1 = " "
        r2 = ""
        row.each_with_index do |cell, x|
          if x % 2 == 0
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

    def add_opening_from(point)
      x, y = point
      if valid?(x, y)
        # nothing to be done
      elsif valid?(x-1, y)
        @cells[y][x-1] |= E
      elsif valid?(x+1, y)
        @cells[y][x+1] |= W
      elsif valid?(x-1, y-1)
        @cells[y-1][x-1] |= S
      elsif valid?(x+1, y+1)
        @cells[y+1][x+1] |= N
      end
    end
  end
end
