require 'minitest/autorun'
require 'theseus'

class MazeTest < MiniTest::Unit::TestCase
  def test_maze_without_explicit_height_uses_width
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal 10, maze.width
    assert_equal maze.width, maze.height
  end

  def test_maze_without_explicit_width_uses_height
    maze = Theseus::OrthogonalMaze.new(height: 10)
    assert_equal 10, maze.height
    assert_equal maze.height, maze.width
  end

  def test_maze_is_initially_blank
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert !maze.generated?

    zeros = 0
    maze.height.times do |y|
      maze.width.times do |x|
        zeros += 1if maze[x, y] == 0
      end
    end

    assert_equal 100, zeros
  end

  def test_maze_created_with_generate_is_identical_to_maze_created_with_step
    srand(14)
    maze1 = Theseus::OrthogonalMaze.generate(width: 10)
    assert maze1.generated?

    srand(14)
    maze2 = Theseus::OrthogonalMaze.new(width: 10)
    maze2.step until maze2.generated?

    assert_equal maze1.width, maze2.width
    assert_equal maze1.height, maze2.height

    differences = 0

    maze1.width.times do |x|
      maze1.height.times do |y|
        differences += 1 unless maze1[x,y] == maze2[x,y]
      end
    end

    assert_equal 0, differences
  end

  def test_apply_move_at_should_combine_direction_with_existing_directions
    maze = Theseus::OrthogonalMaze.new(width: 10)

    maze[5,5] = Theseus::Maze::E
    maze.apply_move_at(5, 5, Theseus::Maze::N)
    assert_equal (Theseus::Maze::N | Theseus::Maze::E), maze[5,5]
  end

  def test_apply_move_at_with_under_should_move_existing_directions_to_under_plane
    maze = Theseus::OrthogonalMaze.new(width: 10)

    maze[5,5] = Theseus::Maze::E
    maze.apply_move_at(5, 5, :under)
    assert_equal (Theseus::Maze::E << Theseus::Maze::UNDER_SHIFT), maze[5,5]
  end

  def test_apply_move_at_with_x_symmetry_should_populate_x_mirror
    maze = Theseus::OrthogonalMaze.new(width: 10, symmetry: :x)

    maze.apply_move_at(1, 2, Theseus::Maze::E)
    assert_equal Theseus::Maze::W, maze[8, 2]

    maze.apply_move_at(2, 1, Theseus::Maze::NE)
    assert_equal Theseus::Maze::NW, maze[7, 1]

    maze.apply_move_at(2, 3, Theseus::Maze::N)
    assert_equal Theseus::Maze::N, maze[7, 3]
  end

  def test_apply_move_at_with_y_symmetry_should_populate_y_mirror
    maze = Theseus::OrthogonalMaze.new(width: 10, symmetry: :y)

    maze.apply_move_at(1, 2, Theseus::Maze::S)
    assert_equal Theseus::Maze::N, maze[1, 7]

    maze.apply_move_at(2, 1, Theseus::Maze::SW)
    assert_equal Theseus::Maze::NW, maze[2, 8]

    maze.apply_move_at(2, 3, Theseus::Maze::W)
    assert_equal Theseus::Maze::W, maze[2, 6]
  end

  def test_apply_move_at_with_xy_symmetry_should_populate_xy_mirror
    maze = Theseus::OrthogonalMaze.new(width: 10, symmetry: :xy)

    maze.apply_move_at(1, 2, Theseus::Maze::S)
    assert_equal Theseus::Maze::N, maze[1, 7]
    assert_equal Theseus::Maze::S, maze[8, 2]
    assert_equal Theseus::Maze::N, maze[8, 7]

    maze.apply_move_at(2, 1, Theseus::Maze::SW)
    assert_equal Theseus::Maze::NW, maze[2, 8]
    assert_equal Theseus::Maze::SE, maze[7, 1]
    assert_equal Theseus::Maze::NE, maze[7, 8]

    maze.apply_move_at(2, 3, Theseus::Maze::W)
    assert_equal Theseus::Maze::W, maze[2, 6]
    assert_equal Theseus::Maze::E, maze[7, 3]
    assert_equal Theseus::Maze::E, maze[7, 6]
  end

  def test_apply_move_at_with_radial_symmetry_should_populate_radial_mirror
    maze = Theseus::OrthogonalMaze.new(width: 10, symmetry: :radial)

    maze.apply_move_at(1, 2, Theseus::Maze::S)
    assert_equal Theseus::Maze::E, maze[2, 8]
    assert_equal Theseus::Maze::W, maze[7, 1]
    assert_equal Theseus::Maze::N, maze[8, 7]

    maze.apply_move_at(2, 1, Theseus::Maze::SW)
    assert_equal Theseus::Maze::SE, maze[1, 7]
    assert_equal Theseus::Maze::NW, maze[8, 2]
    assert_equal Theseus::Maze::NE, maze[7, 8]

    maze.apply_move_at(2, 3, Theseus::Maze::W)
    assert_equal Theseus::Maze::S, maze[3, 7]
    assert_equal Theseus::Maze::N, maze[6, 2]
    assert_equal Theseus::Maze::E, maze[7, 6]
  end

  def test_dx_east_should_increase
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal 1, maze.dx(Theseus::Maze::E)
    assert_equal 1, maze.dx(Theseus::Maze::NE)
    assert_equal 1, maze.dx(Theseus::Maze::SE)
  end

  def test_dx_west_should_decrease
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal -1, maze.dx(Theseus::Maze::W)
    assert_equal -1, maze.dx(Theseus::Maze::NW)
    assert_equal -1, maze.dx(Theseus::Maze::SW)
  end

  def test_dy_south_should_increase
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal 1, maze.dy(Theseus::Maze::S)
    assert_equal 1, maze.dy(Theseus::Maze::SE)
    assert_equal 1, maze.dy(Theseus::Maze::SW)
  end

  def test_dy_north_should_decrease
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal -1, maze.dy(Theseus::Maze::N)
    assert_equal -1, maze.dy(Theseus::Maze::NE)
    assert_equal -1, maze.dy(Theseus::Maze::NW)
  end

  def test_opposite_should_report_inverse_direction
    maze = Theseus::OrthogonalMaze.new(width: 10)
    assert_equal Theseus::Maze::N, maze.opposite(Theseus::Maze::S)
    assert_equal Theseus::Maze::NE, maze.opposite(Theseus::Maze::SW)
    assert_equal Theseus::Maze::E, maze.opposite(Theseus::Maze::W)
    assert_equal Theseus::Maze::SE, maze.opposite(Theseus::Maze::NW)
    assert_equal Theseus::Maze::S, maze.opposite(Theseus::Maze::N)
    assert_equal Theseus::Maze::SW, maze.opposite(Theseus::Maze::NE)
    assert_equal Theseus::Maze::W, maze.opposite(Theseus::Maze::E)
    assert_equal Theseus::Maze::NW, maze.opposite(Theseus::Maze::SE)
  end

  def test_step_should_populate_current_cell_and_next_cell
    maze = Theseus::OrthogonalMaze.new(width: 10)

    cx, cy = maze.x, maze.y
    assert cx >= 0 && cx < maze.width
    assert cy >= 0 && cy < maze.height
    assert_equal 0, maze[cx, cy]

    assert maze.step

    direction = maze[cx, cy]
    refute_equal 0, direction

    nx, ny = maze.move(cx, cy, direction)
    refute_equal [nx, ny], [cx, cy]
    assert_equal [nx, ny], [maze.x, maze.y]

    assert_equal maze.opposite(direction), maze[nx, ny]
  end
end
