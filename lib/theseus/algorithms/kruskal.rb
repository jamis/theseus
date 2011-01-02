require 'theseus/algorithms/base'

module Theseus
  module Algorithms
    # Kruskal's algorithm is a means of finding a minimum spanning tree for a
    # weighted graph. By changing how edges are selected, it becomes suitable
    # for use as a maze generator.
    #
    # The mazes it generates tend to have a lot of short cul-de-sacs, which
    # on the one hand makes the maze look "spiky", but on the other hand
    # can potentially make the maze harder to solve.
    #
    # This implementation of Kruskal's algorithm does not support weave
    # mazes.
    class Kruskal < Base
      class TreeSet #:nodoc:
        attr_accessor :parent

        def initialize
          @parent = nil
        end

        def root
          @parent ? @parent.root : self
        end

        def connected?(tree)
          root == tree.root
        end

        def connect(tree)
          tree.root.parent = self
        end
      end

      def initialize(maze, options={}) #:nodoc:
        super

        if @maze.weave > 0
          raise ArgumentError, "weave mazes cannot be generated with kruskal's algorithm"
        end

        @sets = Array.new(@maze.height) { Array.new(@maze.width) { TreeSet.new } }
        @edges = []

        maze.height.times do |y|
          maze.row_length(y).times do |x|
            next unless @maze.valid?(x, y)
            @maze.potential_exits_at(x, y).each do |dir|
              dx, dy = @maze.dx(dir), @maze.dy(dir)
              if (dx < 0 || dy < 0) && @maze.valid?(x+dx, y+dy)
                weight = rand(100) < @maze.randomness ? 0.5 + rand : 1
                @edges << [x, y, dir, weight]
              end
            end
          end
        end

        @edges = @edges.sort_by { |e| e.last }
      end

      def do_step #:nodoc:
        until @edges.empty?
          x, y, direction, _ = @edges.pop
          nx, ny = x + @maze.dx(direction), y + @maze.dy(direction)

          set1, set2 = @sets[y][x], @sets[ny][nx]
          unless set1.connected?(set2)
            set1.connect(set2)
            @maze.apply_move_at(x, y, direction)
            @maze.apply_move_at(nx, ny, @maze.opposite(direction))
            return true
          end
        end

        @pending = false
        return false
      end
    end
  end
end
