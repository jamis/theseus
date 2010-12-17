require 'theseus/formatters/png'

module Theseus
  module Formatters
    class PNG
      class Sigma < PNG
        def initialize(maze, options={})
          super

          width = @options[:outer_padding] * 2 + (3 * maze.width + 1) * @options[:cell_size] / 4
          height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size] + @options[:cell_size] / 2

          canvas = ChunkyPNG::Image.new(width, height, @options[:background])

          maze.height.times do |y|
            py = @options[:outer_padding] + y * @options[:cell_size]
            maze.row_length(y).times do |x|
              px = @options[:outer_padding] + x * 3 * @options[:cell_size] / 4.0
              shifted = (x % 2 != 0)
              dy = shifted ? (@options[:cell_size] / 2.0) : 0
              draw_cell(canvas, [x, y], shifted, px, py+dy, maze[x, y])
            end
          end

          @blob = canvas.to_blob
        end

        def draw_cell(canvas, point, shifted, x, y, cell)
          return if cell == 0

          size = options[:cell_size] - options[:cell_padding] * 2
          s4 = size / 4.0

          fs4 = options[:cell_size] / 4.0 # fs == full-size, without padding

          p1 = [x + options[:cell_padding] + s4, y + options[:cell_padding]]
          p2 = [x + options[:cell_size] - options[:cell_padding] - s4, p1[1]]
          p3 = [x + options[:cell_padding] + size, y + options[:cell_size] / 2.0]
          p4 = [p2[0], y + options[:cell_size] - options[:cell_padding]]
          p5 = [p1[0], p4[1]]
          p6 = [x + options[:cell_padding], p3[1]]

          fill_poly(canvas, [p1, p2, p3, p4, p5, p6], color_at(point))

          n  = Maze::N
          s  = Maze::S
          nw = shifted ? Maze::W : Maze::NW
          ne = shifted ? Maze::E : Maze::NE
          sw = shifted ? Maze::SW : Maze::W
          se = shifted ? Maze::SE : Maze::E

          any = proc { |x| x | (x << Maze::UNDER_SHIFT) }

          if cell & any[s] != 0
            r1, r2 = p5, move(p4, 0, options[:cell_padding]*2)
            fill_rect(canvas, r1[0], r1[1], r2[0], r2[1], color_at(point, any[s]))
            line(canvas, p5, move(p5, 0, options[:cell_padding]*2), options[:wall_color])
            line(canvas, p4, move(p4, 0, options[:cell_padding]*2), options[:wall_color])
          end

          if cell & any[ne] != 0
            ne_x = x + 3 * options[:cell_size] / 4.0
            ne_y = y - options[:cell_size] * 0.5
            ne_p5 = [ne_x + options[:cell_padding] + s4, ne_y + options[:cell_size] - options[:cell_padding]]
            ne_p6 = [ne_x + options[:cell_padding], ne_y + options[:cell_size] * 0.5]
            r1, r2, r3, r4 = p2, p3, ne_p5, ne_p6
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, any[ne]))
            line(canvas, r1, r4, options[:wall_color])
            line(canvas, r2, r3, options[:wall_color])
          end

          if cell & any[se] != 0
            se_x = x + 3 * options[:cell_size] / 4.0
            se_y = y + options[:cell_size] * 0.5
            se_p1 = [se_x + s4 + options[:cell_padding], se_y + options[:cell_padding]]
            se_p6 = [se_x + options[:cell_padding], se_y + options[:cell_size] * 0.5]
            r1, r2, r3, r4 = p3, p4, se_p6, se_p1
            fill_poly(canvas, [r1, r2, r3, r4], color_at(point, any[se]))
            line(canvas, r1, r4, options[:wall_color])
            line(canvas, r2, r3, options[:wall_color])
          end

          line(canvas, p1, p2, options[:wall_color]) if cell & n == 0
          line(canvas, p2, p3, options[:wall_color]) if cell & ne == 0
          line(canvas, p3, p4, options[:wall_color]) if cell & se == 0
          line(canvas, p4, p5, options[:wall_color]) if cell & s == 0
          line(canvas, p5, p6, options[:wall_color]) if cell & sw == 0
          line(canvas, p6, p1, options[:wall_color]) if cell & nw == 0
        end
      end
    end
  end
end

