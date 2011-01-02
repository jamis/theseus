require 'optparse'
require 'theseus'
require 'theseus/formatters/png'

require 'theseus/algorithms/recursive_backtracker'
require 'theseus/algorithms/kruskal'
require 'theseus/algorithms/prim'

module Theseus
  class CLI
    TYPE_MAP = {
      "ortho"   => Theseus::OrthogonalMaze,
      "delta"   => Theseus::DeltaMaze,
      "sigma"   => Theseus::SigmaMaze,
      "upsilon" => Theseus::UpsilonMaze,
    }

    ALGO_MAP = {
      "backtrack" => Theseus::Algorithms::RecursiveBacktracker,
      "kruskal"   => Theseus::Algorithms::Kruskal,
      "prim"      => Theseus::Algorithms::Prim,
    }

    def self.run(*args)
      new(*args).run
    end

    attr_accessor :animate
    attr_accessor :delay
    attr_accessor :output
    attr_accessor :sparse
    attr_accessor :unicursal
    attr_accessor :type
    attr_accessor :format
    attr_accessor :solution

    attr_reader   :maze_opts
    attr_reader   :png_opts

    def initialize(*args)
      args.flatten!

      @animate = false
      @delay = 50
      @output = "maze"
      @sparse = 0
      @unicursal = false
      @type = "ortho"
      @format = :ascii
      @solution = nil

      @png_opts = Theseus::Formatters::PNG::DEFAULTS.dup
      @maze_opts = { mask: nil, width: nil, height: nil,
        randomness: 50, weave: 0, symmetry: :none, braid: 0, wrap: :none,
        entrance: nil, exit: nil, algorithm: ALGO_MAP["backtrack"] }

      option_parser.parse!(args)

      if args.any?
        abort "extra arguments detected: #{args.inspect}"
      end

      normalize_settings!
    end

    def run
      if @animate
        run_animation
      else
        run_static
      end
    end

    private

    def run_animation
      if format == :ascii
        run_ascii_animation
      else
        run_png_animation
      end
    end

    def clear_screen
      print "\e[2J"
    end

    def cursor_home
      print "\e[H"
    end

    def show_maze
      cursor_home
      puts @maze.to_s(:mode => :unicode)
    end

    def run_ascii_animation
      clear_screen

      @maze.generate! do
        show_maze
        sleep(@delay)
      end

      show_maze
    end

    def write_frame(step, options={})
      f = "%s-%04d.png" % [@output, step]
      step += 1
      File.open(f, "w") { |io| io.write(@maze.to(:png, @png_opts.merge(options))) }
      print "."
    end

    def run_png_animation
      step = 0
      @maze.generate! do
        write_frame(step)
        step += 1
      end

      write_frame(step)
      step += 1

      if @solution
        solver = @maze.new_solver(type: @solution)

        while solver.step
          path = solver.to_path(color: @png_opts[:solution_color])
          write_frame(step, paths: [path])
          step += 1
        end
      end

      puts
      puts "done, %d frames written to %s-*.png" % [step, @output]
    end

    def run_static
      @maze.generate!
      @sparse.times { @maze.sparsify! }

      if @unicursal
        enter_at = @unicursal_entrance || [-1,0]
        if enter_at[0] > 0 && enter_at[0] < width*2
          exit_at = [enter_at[0]+1, enter_at[1]]
        else
          exit_at = [enter_at[0], enter_at[1]+1]
        end
        @maze = @maze.to_unicursal(entrance: enter_at, exit: exit_at)
      end

      if @format == :ascii
        puts @maze.to_s(:mode => :unicode)
      else
        File.open(@output + ".png", "w") { |io| io.write(@maze.to(:png, @png_opts)) }
        puts "maze written to #{@output}.png"
      end
    end

    def normalize_settings!
      # default width to height, and vice-versa
      @maze_opts[:width] ||= @maze_opts[:height]
      @maze_opts[:height] ||= @maze_opts[:width]

      if @maze_opts[:mask].nil? && (@maze_opts[:width].nil? || @maze_opts[:height].nil?)
        warn "You must specify either a mask (-m) or the maze dimensions(-w or -H)."
        abort "Try --help for a full list of options."
      end

      if @animate
        abort "sparse cannot be used for animated mazes" if @sparse > 0
        abort "cannot animate unicursal mazes" if @unicursal

        if @format != :ascii
          @png_opts[:background] = ChunkyPNG::Color.from_hex(@png_opts[:background]) unless Fixnum === @png_opts[:background]

          if @png_opts[:background] & 0xFF != 0xFF
            warn "if you intend to make a movie out of the frames from the animation,"
            warn "it is HIGHLY RECOMMENDED that you use a fully opaque background color."
          end
        end

        # convert delay to a fraction of a second
        @delay = @delay / 1000.0
      end

      if @solution
        abort "cannot display solution in ascii mode" if @format == :ascii
      end

      if @unicursal
        @unicursal_entrance = @maze_opts.delete(:entrance)
        @maze_opts[:entrance] = [0,0]
        @maze_opts[:exit] = [0,0]
      end

      @maze_opts[:mask] ||= Theseus::TransparentMask.new(@maze_opts[:width], @maze_opts[:height])
      @maze_opts[:width] ||= @maze_opts[:mask].width
      @maze_opts[:height] ||= @maze_opts[:mask].height
      @maze = TYPE_MAP[@type].new(@maze_opts)

      if @unicursal && !@maze.respond_to?(:to_unicursal)
        abort "#{@type} mazes do not support the -u (unicursal) option"
      end
    end

    def option_parser
      OptionParser.new do |opts|
        setup_required_options(opts)
        setup_output_options(opts)
        setup_maze_options(opts)
        setup_formatting_options(opts)
        setup_misc_options(opts)
      end
    end

    def setup_required_options(opts)
      opts.separator ""
      opts.separator "Required options:"

      opts.on("-w", "--width N", Integer, "width of the maze (default 20, or mask width)") do |w|
        @maze_opts[:width] = w
      end

      opts.on("-H", "--height N", Integer, "height of the maze (default 20 or mask height)") do |h|
        @maze_opts[:height] = h
      end

      opts.on("-m", "--mask FILE", "png file to use as mask") do |m|
        case m
        when /^triangle:(\d+)$/ then @maze_opts[:mask] = Theseus::TriangleMask.new($1.to_i)
        else @maze_opts[:mask] = Theseus::Mask.from_png(m)
        end
      end
    end

    def setup_output_options(opts)
      opts.separator ""
      opts.separator "Output options:"

      opts.on("-a", "--[no-]animate", "emit frames for each step") do |v|
        @animate = v
      end

      opts.on("-D", "--delay N", Integer, "time to wait between animation frames, in ms, default is #{@delay}") do |d|
        @delay = d
      end

      opts.on("-o", "--output FILE", "where to save the file(s) (for png only)") do |f|
        @output = f
      end

      opts.on("-f", "--format FMT", "png, ascii (default #{@format})") do |f|
        @format = f.to_sym
      end

      opts.on("-V", "--solve [METHOD]", "whether to display the solution of the maze.", "METHOD is either `backtracker' (the default) or `astar'") do |s|
        @solution = (s || :backtracker).to_sym
      end
    end

    def setup_maze_options(opts)
      opts.separator ""
      opts.separator "Maze options:"

      opts.on("-s", "--seed N", Integer, "random seed to use") do |s|
        srand(s)
      end

      opts.on("-A", "--algorithm NAME", "the algorithm to use to generate the maze.",
                                        "may be any of #{ALGO_MAP.keys.sort.join(",")}.",
                                        "defaults to `backtrack'.") do |a|
        @maze_opts[:algorithm] = ALGO_MAP[a] or abort "unknown algorithm `#{a}'"
      end

      opts.on("-t", "--type TYPE", "#{TYPE_MAP.keys.sort.join(",")} (default: #{@type})") do |t|
        @type = t
      end

      opts.on("-u", "--[no-]unicursal", "generate a unicursal maze (results in 2x size)") do |u|
        @unicursal = u
      end

      opts.on("-y", "--symmetry TYPE", "one of none,x,y,xy,radial (default is '#{@maze_opts[:symmetry]}')") do |s|
        @maze_opts[:symmetry] = s.to_sym
      end

      opts.on("-e", "--weave N", Integer, "0-100, chance of a passage to go over/under another (default #{@maze_opts[:weave]})") do |v|
        @maze_opts[:weave] = v
      end

      opts.on("-r", "--random N", Integer, "0-100, randomness of maze (default #{@maze_opts[:randomness]})") do |r|
        @maze_opts[:randomness] = r
      end

      opts.on("-S", "--sparse N", Integer, "how sparse to make the maze (default #{@sparse})") do |s|
        @sparse = s
      end

      opts.on("-d", "--braid N", Integer, "0-100, percentage of deadends to remove (default #{maze_opts[:braid]})") do |b|
        @maze_opts[:braid] = b
      end

      opts.on("-R", "--wrap axis", "none,x,y,xy (default #{@maze_opts[:wrap]})") do |w|
        @maze_opts[:wrap] = w.to_sym
      end

      opts.on("-E", "--enter [X,Y]", "the entrance of the maze (default -1,0)") do |s|
        @maze_opts[:entrance] = s.split(/,/).map { |v| v.to_i }
      end

      opts.on("-X", "--exit [X,Y]", "the exit of the maze (default width,height-1)") do |s|
        @maze_opts[:exit] = s.split(/,/).map { |v| v.to_i }
      end
    end

    def setup_formatting_options(opts)
      opts.separator ""
      opts.separator "Formatting options:"

      opts.on("-B", "--background COLOR", "rgba hex background color for maze (default %08X)" % @png_opts[:background]) do |c|
        @png_opts[:background] = c
      end

      opts.on("-C", "--cellcolor COLOR", "rgba hex cell color for maze (default %08X)" % @png_opts[:cell_color]) do |c|
        @png_opts[:cell_color] = c
      end

      opts.on("-L", "--wallcolor COLOR", "rgba hex wall color for maze (default %08X)" % @png_opts[:wall_color]) do |c|
        @png_opts[:wall_color] = c
      end

      opts.on("-U", "--solutioncolor COLOR", "rgba hex color for the answer path (default %08X)" % @png_opts[:solution_color]) do |c|
        @png_opts[:solution_color] = c
      end

      opts.on("-c", "--cell N", Integer, "size of each cell (default #{@png_opts[:cell_size]})") do |c|
        @png_opts[:cell_size] = c
      end

      opts.on("-b", "--border N", Integer, "border padding around outside (default #{@png_opts[:outer_padding]})") do |c|
        @png_opts[:outer_padding] = c
      end

      opts.on("-p", "--padding N", Integer, "padding around cell (default #{@png_opts[:cell_padding]})") do |c|
        @png_opts[:cell_padding] = c
      end

      opts.on("-W", "--wall N", Integer, "thickness of walls (default #{@png_opts[:wall_width]})") do |c|
        @png_opts[:wall_width] = c
      end
    end

    def setup_misc_options(opts)
      opts.separator ""
      opts.separator "Other options:"

      opts.on_tail("-v", "--version", "display the Theseus version and exit") do
        maze = Theseus::OrthogonalMaze.generate(width: 20, height: 4)
        s = maze.to_s(mode: :lines).strip
        print s.gsub(/^/, "          ").sub(/^\s*/, "theseus --")

        require 'theseus/version'
        puts "--> v#{Theseus::Version::STRING}"
        puts "a maze generator, renderer, and solver by Jamis Buck <jamis@jamisbuck.org>"
        exit
      end

      opts.on_tail("-h", "--help", "this helpful list of options") do
        puts opts
        exit
      end
    end
  end
end
