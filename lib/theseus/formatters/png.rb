# encoding: UTF-8

require 'chunky_png'

module Theseus
  module Formatters
    class PNG
      DEFAULTS = {
        :cell_size     => 5,
        :wall_width    => 1,
        :wall_color    => 0x000000FF,
        :cell_color    => 0xFFFFFFFF,
        :background    => 0x00000000,
        :outer_padding => 0,
        :cell_padding  => 1,
      }

      def initialize(maze, options={})
        @options = DEFAULTS.merge(options)

        width  = @options[:outer_padding] * 2 + maze.width * @options[:cell_size]
        height = @options[:outer_padding] * 2 + maze.height * @options[:cell_size]
        
        [:background, :wall_color, :cell_color].each do |c|
          @options[c] = ChunkyPNG::Color.from_hex(@options[c]) unless Fixnum === @options[c]
        end

        canvas = ChunkyPNG::Image.new(width, height, @options[:background])
        def canvas.fill_rect(x0, y0, x1, y1, color)
          [x0, x1].min.upto([x0, x1].max) do |x|
            [y0, y1].min.upto([y0, y1].max) do |y|
              point(x, y, color)
            end
          end
        end

        @d1 = @options[:cell_padding]
        @d2 = @options[:cell_size] - @options[:cell_padding]
        @w1 = (@options[:wall_width] / 2.0).floor
        @w2 = ((@options[:wall_width] - 1) / 2.0).floor

        maze.height.times do |y|
          py = @options[:outer_padding] + y * @options[:cell_size]
          maze.width.times do |x|
            px = @options[:outer_padding] + x * @options[:cell_size]
            draw_cell(canvas, px, py, maze[x, y])
          end
        end

        @blob = canvas.to_blob
      end

      def to_blob
        @blob
      end

      def draw_cell(canvas, x, y, cell)
        return if cell == 0

        canvas.fill_rect(x + @d1, y + @d1, x + @d2, y + @d2, @options[:cell_color])

        draw_vertical(canvas, x, y, 1, cell & Theseus::Maze::NORTH)
        draw_vertical(canvas, x, y + @options[:cell_size], -1, cell & Theseus::Maze::SOUTH)
        draw_horizontal(canvas, x, y, 1, cell & Theseus::Maze::WEST)
        draw_horizontal(canvas, x + @options[:cell_size], y, -1, cell & Theseus::Maze::EAST)
      end

      def draw_vertical(canvas, x, y, direction, cell)
        if cell != 0
          canvas.fill_rect(x + @d1, y, x + @d2, y + @d1 * direction, @options[:cell_color])
          canvas.fill_rect(x + @d1 - @w1, y - (@w1 * direction), x + @d1 + @w2, y + (@d1 + @w2) * direction, @options[:wall_color])
          canvas.fill_rect(x + @d2 - @w2, y - (@w1 * direction), x + @d2 + @w1, y + (@d1 + @w2) * direction, @options[:wall_color])
        else
          canvas.fill_rect(x + @d1 - @w1, y + (@d1 - @w1) * direction, x + @d2 + @w2, y + (@d1 + @w2) * direction, @options[:wall_color])
        end
      end

      def draw_horizontal(canvas, x, y, direction, cell)
        if cell != 0
          canvas.fill_rect(x, y + @d1, x + @d1 * direction, y + @d2, @options[:cell_color])
          canvas.fill_rect(x - (@w1 * direction), y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d1 + @w2, @options[:wall_color])
          canvas.fill_rect(x - (@w1 * direction), y + @d2 - @w2, x + (@d1 + @w2) * direction, y + @d2 + @w1, @options[:wall_color])
        else
          canvas.fill_rect(x + (@d1 - @w1) * direction, y + @d1 - @w1, x + (@d1 + @w2) * direction, y + @d2 + @w2, @options[:wall_color])
        end
      end
    end
  end
end
