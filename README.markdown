Theseus
=======

Theseus is a maze generation library for Ruby. It's features are:

* Generate mazes with a single line of code.
* Easily animate the process of building the maze.
* Display the solution to a generated maze.
* Output the maze as either text or PNG.
* Apply a mask to the process to constrain how the maze is built.
* Culling dead-ends from a maze to increase its sparseness.
* Convert any orthogonal maze to a unicursal (labyrinth-style) maze.
* Generate mazes with high braid or low braid (or anything in-between). (a "perfectly braided" maze is completely multiply-connected, with no dead-ends and circular paths)
* Generate mazes with high weave or low weave (or anything in-between). ("weave" refers to how frequently passages move under or over existing passages.)
* Generate mazes with various types of symmetry (x, y, xy, radial)
* Various maze types, including:
  * orthogonal (the default). Square cells with 4 exits each.
  * delta. Triangular cells with 3 exits each.
  * sigma. Hexagonal cells with 6 exits each.
  * upsilon. Octagonal and square cells with 8 or 4 exits each.

Requirements
============

* Ruby 1.9
* ChunkyPNG library

Installation
============

    gem install theseus

Usage
=====

The gem installs a command that may be used to generate mazes from the
command-line:

    $ theseus -w 10 -H 10

The above command would generate a 10x10 maze and write it out to "maze.png".
Pass the "-h" option for a list of all supported options.

Alternatively, you can build the mazes programmatically:

    require 'theseus/orthogonal_maze'

    maze1 = Theseus::OrthogonalMaze.generate(10, 10)
    File.open("maze.png", "w") { |f| f.write(maze1.to(:png)) }

    mask = Theseus::Mask.from_png("mask.png")
    maze2 = Theseus::OrthogonalMaze.new(mask.width, mask.height, weave: 50,
      randomness: 100, mask: mask)
    n = 0
    while maze2.step
      File.open("frame-%04d.png" % n, "w") { |f| f.write(maze2.to(:png)) }
      n += 1
    end

License
=======

Theseus is a creation of Jamis Buck, who has placed it in the public domain.
The code may be taken and put to whatever nefarious use you might desire,
without restriction.
