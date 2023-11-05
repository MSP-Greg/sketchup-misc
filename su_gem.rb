# frozen_string_literal: true
# Code by MSP-Greg

# Utility to use RubyGems in SketchUp's Ruby console
#
# In the Ruby console:
#    load '<path to this file>'
#
# Some gems commands may require user interaction.  These commands are not supported.
# An example would be uninstalling a gem that has multiple versions installed.
# To use the uninstall command, one will need to specify which version to uninstall:
#
#    SUGem.uninstall "minitest:5.20.0"
#
# Note that Gems cannot be installed in SketchUp if they require compiling.
#
# Run by using using gem command as method
#
#     SUGem.env
#     SUGem.install "minitest:5.20.0"
#     SUGem.install "hike --user-install -N"
#     SUGem.uninstall "hike"
#     SUGem.list "hike -d"
#     SUGem.list "-d"
#     SUGem.outdated
#
# Or you can run by using a full command string as below.  Note that the passed
# string is identical to what one would use from the command line with a
# stand-alone Ruby, but with `gem ` removed
#
#     SUGem.run "install hike --user-install -N"
#
# An additional command is available, which lists all gems available to SketchUp,
# and also shows their location/type.
# The command is `SUGem.su_gem_list`
#
module SUGem

  GEM_PLATFORMS = Gem.platforms.reject { |p| p == 'ruby' }.map(&:to_s)

  class << self

    def run args
      returned = false
      @is_loaded ||= false

      # load here so only loaded when run
      unless @is_loaded
        require 'stringio'
        require 'rubygems'
        require 'rubygems/command_manager'
        require 'rubygems/config_file'
        require 'rubygems/deprecate'
        require 'openssl'
        @is_loaded = true
      end

      ary_args = args.split(/ +/)

      cmd = Gem::CommandManager.instance
      # fix abbreviation
      ary_args[0] = 'environment' if ary_args[0] == 'env'

      unless cmd.command_names.include? ary_args[0]
        puts "SUGem - #{ary_args[0]} is not a valid gem command!"
        returned = true
        return
      end

      build_args = extract_build_args ary_args

      do_configuration ary_args

      cmd.command_names.each do |command_name|
        config_args = Gem.configuration[command_name]
        config_args = case config_args
                      when String
                        config_args.split ' '
                      else
                        Array(config_args)
                      end
        Gem::Command.add_specific_extra_args command_name, config_args
      end

      sio_in = StringIO.new
      sio_out, sio_err = StringIO.new, StringIO.new
      cmd.ui = Gem::StreamUI.new(sio_in, sio_out, sio_err, false)

      cmd.run Gem.configuration.args, build_args
      t = sio_err.string
      puts "-- error --\n#{t}\n" unless t.empty?
    rescue Gem::SystemExitException => e
      t = e.message
      puts t unless t.end_with? "exit_code 0"
      t = sio_err.string
      puts t unless t.empty?
    ensure
      return if returned
      t = sio_out ? sio_out.string : ''
      puts t unless t.empty?
      sio_in&.close
      sio_out&.close
      sio_err&.close
    end

    def su_gem_list
      dash  = 8212.chr(Encoding::UTF_8)
      width = 75
      dash_line = dash * width

      # if a gem exists in multiple locations, @names[name] will be > 1
      names = Hash.new { |h,k| h[k] = 0 }
      dflt_spec_dir = Gem.respond_to?(:default_specifications_dir) ?
        Gem.default_specifications_dir : Gem::BasicSpecification.default_specifications_dir
      dflt      = extract names, dflt_spec_dir
      bundled   = extract names, File.join(Gem.default_dir, 'specifications')
      installed = extract names, File.join(Gem.dir        , 'specifications')
      user      = extract names, File.join(Gem.user_dir   , 'specifications')

      str =  "\n#{dash_line} Installed Gems\n".dup
      str << "Bundled   #{Gem.default_dir}\n"
      str << "Installed #{Gem.dir}\n"
      str << "User      #{Gem.user_dir}\n"
      str << "* gem exists in multiple locations\n\n"

      str << "#{dash * 12} Default Gems #{dash * 12}\n"
      str << output(names, dflt, "D ")

      str << "#{dash * 12} Bundled Gems #{dash * 12} \n"
      str << output(names, bundled, "B ")

      str << "#{dash * 12} Installed Gems #{dash * 10} \n"
      str << output(names, installed, "I ")

      str << "#{dash * 12} User Gems #{dash    * 15} \n"
      str << output(names, user, "U ")
      puts str.gsub(/#{ENV['USER']}/, '<user>')
    end

    private

    ##
    # Separates the build arguments (those following <code>--</code>) from the
    # other arguments in the list.

    def extract_build_args args # :nodoc:
      return [] unless offset = args.index('--')
      build_args = args.slice!(offset...args.length)
      build_args.shift
      build_args
    end

    def do_configuration(args)
      Gem.configuration = Gem::ConfigFile.new(args)
      Gem.use_paths Gem.configuration[:gemhome], Gem.configuration[:gempath]
      Gem::Command.extra_args = Gem.configuration[:gem]
    end

    # used by su_gem_list
    #
    def output(names, ary, pre)
      cntr = 1
      str = ''.dup
      ary.each do |a|
        if names[a[0]] > 1
          str << "#{pre} #{a[0].ljust 25} * #{a[1]}\n"
        else
          str << "#{pre} #{a[0].ljust 25}   #{a[1]}\n"
        end
        str << "\n" if (cntr % 5) == 0
        cntr += 1
      end
      # str can contain two returns at end
      str.rstrip + "\n\n"
    end

    # used by su_gem_list
    #
    def extract(names, spec_dir)
      gem_ary = Dir['*.gemspec', base: spec_dir]

      if GEM_PLATFORMS.any? { |p| p.include? 'mswin' }
        exclude = %w[-x64-mingw32 -x64-mingw-ucrt]
      else
        exclude = nil
      end

      ary = []
      gem_ary.each do |fn|
        full = fn.sub(/\.gemspec\z/, '').dup
        if exclude
          next if exclude.any? { |p| full.end_with? p }
        end
        platform = nil
        GEM_PLATFORMS.each do |p|
          if full.end_with? p
            platform = p
            full.sub! "-#{p}", ''
            break
          end
        end

        name, _, vers = full.rpartition '-'

        ary << [name, Gem::Version.new(vers), platform]
      end

      hsh = ary.group_by(&:first)
      ary = []
      hsh.each do |k,v|
        val = v.sort { |a,b| b[1] <=> a[1] }
          .map { |i| i[2].nil? ? i[1] : "#{i[1]}-#{i[2]}" }
          .join ' '
        ary << [k, val]
        names[k] += 1
      end
      ary.sort
    end

    def method_missing(meth, arg = '')
      raise ArgumentError('SUGem - argument must be a string') unless String === arg
      arg =  "#{meth} #{arg}"
      run arg
    end
  end # class << self
end
