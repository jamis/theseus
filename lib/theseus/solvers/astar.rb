require 'theseus/solvers/base'

module Theseus
  module Solvers
    class Astar < Base
      class Node
        include Comparable

        attr_accessor :point, :under, :path_cost, :estimate, :cost, :next
        attr_reader :history

        def initialize(point, under, path_cost, estimate, history)
          @point, @under, @path_cost, @estimate = point, under, path_cost, estimate
          @history = history
          @cost = path_cost + estimate
        end

        def <=>(node)
          cost <=> node.cost
        end
      end

      attr_reader :open

      def initialize(maze, a=maze.start, b=maze.finish)
        super
        @open = Node.new(@a, false, 0, estimate(@a), [])
        @visits = Array.new(@maze.height) { Array.new(@maze.width, 0) }
      end

      def step
        return false unless @open

        current = @open

        if current.point == @b
          @open = nil
          @solution = current.history + [@b]
        else
          @open = @open.next

          @visits[current.point[1]][current.point[0]] |= current.under ? 2 : 1

          cell = @maze[current.point[0], current.point[1]]

          directions = @maze.potential_exits_at(current.point[0], current.point[1])
          directions.each do |dir|
            try = current.under ? (dir << Theseus::Maze::UNDER_SHIFT) : dir
            if cell & try != 0
              point = move(current.point, dir)
              next unless @maze.valid?(point[0], point[1])
              under = ((@maze[point[0], point[1]] >> Theseus::Maze::UNDER_SHIFT) & @maze.opposite(dir) != 0)
              add_node(point, under, current.path_cost+1, current.history + [current.point])
            end
          end
        end

        return current
      end

      private

      def estimate(pt)
        Math.sqrt((@b[0] - pt[0])**2 + (@b[1] - pt[1])**2)
      end

      def add_node(pt, under, path_cost, history)
        return if @visits[pt[1]][pt[0]] & (under ? 2 : 1) != 0

        node = Node.new(pt, under, path_cost, estimate(pt), history)

        if @open
          p, n = nil, @open

          while n && n < node
            p = n
            n = n.next
          end

          if p.nil?
            node.next = @open
            @open = node
          else
            node.next = n
            p.next = node
          end

          # remove duplicates
          while node.next && node.next.point == node.point
            node.next = node.next.next
          end
        else
          @open = node
        end
      end

      def move(pt, direction)
        [pt[0] + @maze.dx(direction), pt[1] + @maze.dy(direction)]
      end
    end
  end
end
