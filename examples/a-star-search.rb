# Demonstrates the following features of Theseus:
#
# * the A* solver algorithm
# * using Theseus::Path objects to customize the render
# * stepping through the solution process in order to animate it
#   (by spitting out a new frame for each step)

require 'theseus'

# use 100% braid, to give a completely multiple-connected maze
# which will show the A* search to best effect (returning not
# just any path through the maze, but the SHORTEST path)
maze = Theseus::OrthogonalMaze.new(width: 15, height: 15, braid: 100)

puts "generating the maze..."
maze.generate!

# get a new solver object using the A* search algorithm.
solver = maze.new_solver(type: :astar)
puts "solving the maze..."

step = 0
renderings = 0

# use a path object to record every attempted route. This is how we'll
# show "stale" paths that the algorithm determined were ineffecient.
stale_paths = maze.new_path(color: 0x9f9f9fff)

while solver.step
  # the open_set path will show all points in the "open set", the sorted
  # set of points that A* uses to determine where to search next.
  open_set = maze.new_path(color: 0xaaffaaff)

  # the histories path shows the routes leading up to each point in the
  # open set.
  histories = maze.new_path(color: 0xaaaaffff)

  # the "best" path is the path that the algorithm currently considers
  # the most promising lead.
  best = maze.new_path(color: 0xffaaaaff)

  # begin with the first node in the open set
  n = solver.open

  while n
    # add the point itself to the open_set path
    open_set.set(n.point)

    # iterate over the node's history and add add the appropriate
    # connections to the "histories" path
    prev = maze.entrance
    n.history.each do |pt|
      how = histories.link(prev, pt)
      histories.set(pt, how)
      prev = pt
    end
    how = histories.link(prev, n.point)
    histories.set(n.point, how)
    n = n.next
  end

  if solver.open
    prev = maze.entrance
    solver.open.history.each do |pt|
      how = best.link(prev, pt)
      best.set(pt, how)
      prev = pt
    end
    best.link(prev, solver.open.point)
  elsif solver.solved?
    prev = maze.entrance
    solver.solution.each do |pt|
      how = best.link(prev, pt)
      best.set(pt, how)
      prev = pt
    end
    best.link(prev, maze.exit)
  end

  # add all previously examined histories to the stale paths.
  stale_paths.add_path(histories)

  # try to keep at least 6 frames animating in the background, to speed
  # things along.

  while renderings > 6
    Process.wait
    renderings -= 1
  end

  renderings += 1

  fork do
    File.open("step-%04d.png" % step, "w" ) do |f|
      f.write(maze.to(:png, cell_size: 20, background: 0x2f2f2fff, paths: [best, open_set, histories, stale_paths]))
    end
  end

  puts "%d..." % step
  step += 1
end

while renderings > 0
  Process.wait
  renderings -= 1
end
