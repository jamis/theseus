# maze = Theseus::Maze.generate(100,100)
# maze.generated? #-> true
# 
# maze = Theseus::Maze.new(100,100)
# maze.generated? #-> false
# maze.generate!
# maze.generated? #-> true
# 
# maze = Theseus::Maze.new(100,100)
# maze.generated? #-> false
# maze.generate! do |x,y|
#   # callback for each new cell
# end
# maze.generated? #-> true
# 
# maze = Theseus::Maze.new(100,100)
# maze.generated? #-> false
# while maze.step
#   # do something
# end
# maze.generated? #-> true
# 
# puts maze[1,2] #-> bit-field representing cell at the given (x,y) position
# 
# puts maze.inspect           #-> maze meta-data summary
# puts maze                   #-> rudimentary ascii representation of maze
# puts maze.to_s(:utf8_lines) #-> line-based ascii representation of maze
# puts maze.to_s(:utf8_halls) #-> utf-8 representation of full corridors
# 
# puts maze.to(:pdf)          #-> return PDF representation
# puts maze.to(:png)          #-> return PNG representation
# puts maze.to(:svg)          #-> return SVG representation
# 
# maze.solution([0,0], [99,99]) #-> return array representation cells visited in solution

require 'theseus/maze'
