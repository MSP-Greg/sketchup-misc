# frozen_string_literal: true
# Code by MSP-Greg

=begin
in SU
  load '<path to file>' ; SUInfo.run :all
For info on avilable commands, run
SUInfo.run :help
SUInfo.run :ruby_info
SUInfo.run :gem_list

in Ruby
  ruby --disable-gems -r<path to file> -e "SUInfo.run :all"
  ruby --disable-gems -r<path to file> -e "SUInfo.run :gem"
=end

require_relative 'ssl_test'

module SUInfo
  
  GEM_PLATFORMS = Gem.platforms.reject { |p| p == 'ruby' }.map(&:to_s)

  VERSION = "0.9.3"
    
  class << self

    def run(*args)
      @@col_wid = [34, 14, 17, 26, 10, 16]
      @dash  = 8212.chr(Encoding::UTF_8)
      @width = 75
      @dash_line = @dash * @width
      @first_col = 25

      SKETCHUP_CONSOLE.clear if defined? SKETCHUP_CONSOLE

      str = "\n#{@dash * (@width + 12)}".dup
      str << "\nSUInfo Utility v#{VERSION}"
      str << (defined?(Sketchup) ? "#{' ' * 30}SketchUp v#{Sketchup.version}\n" : "\n" )

      user = /#{ENV['USER']}/
      ary_all = [:all]
      run_all = (args == [:all] || args.empty?)

      str << env           if args.include?(:env)          || run_all
      str << path          if args.include?(:path)         || run_all
      str << encodings     if args.include?(:encodings)    || run_all
      str << ruby_info     if args.include?(:ruby_info)    || run_all
      str << gem_settings  if args.include?(:gem_settings) || run_all || args.include?(:gem)
      str << gem_env       if args.include?(:gem_env)      || run_all || args.include?(:gem)
      str << gem_list      if args.include?(:gem_list)     || run_all || args.include?(:gem)
      str << help          if args.include?(:help)

      str << "#{@dash * (@width + 12)}\n"
      # replace user name for public display
      puts str.gsub(/#{ENV['USER']}/, '<user>')

    end

    private

    def encodings
      "#{@dash_line} Encodings\n" \
     "#{'default_external'.ljust(@first_col)}#{Encoding.default_external}\n" \
     "#{'default_internal'.ljust(@first_col)}#{Encoding.default_internal}\n" \
     "#{'filesystem'.ljust(@first_col)}#{      Encoding.find('filesystem')}\n" \
     "#{'locale'.ljust(@first_col)}#{          Encoding.find('locale')}\n\n"
    end

    def env
      str = "#{@dash_line} ENV\n".dup
      ENV.each { |k,v|
        next if k =~ /\Apath\Z/i
        str << "#{k.ljust(@first_col)}#{v}\n"
      }
      "#{str}\n"
    end

    def gem_env
      require 'rubygems' unless defined? Gem
      require 'rubygems/commands/environment_command'

      strm_io = gem_setup

      # create environment command & attach io
      cmd = Gem::Commands::EnvironmentCommand.new
      cmd.ui = strm_io
      cmd.options[:args] = []

      # environment execute / puts
      cmd.execute
      str = "#{@dash_line} Gem Environment\n".dup
      str << strm_io.outs.string
      gem_teardown strm_io
      "#{str}\n"
    end

    def gem_list
      # if a gem exists in multiple locations, @names[name] will be > 1
      names = Hash.new { |h,k| h[k] = 0 }
      dflt  = extract names, Gem.default_specifications_dir
      build = extract names, File.join(Gem.default_dir, 'specifications')
      user  = extract names, File.join(Gem.user_dir   , 'specifications')

      str =  "#{@dash_line} Installed Gems\n".dup
      str << "Build   #{Gem.dir}\n"
      str << "User    #{Gem.user_dir}\n"
      str << "* gem exists in multiple locations\n\n" 

      str << "#{@dash * 11} Default Gems #{@dash * 11}\n"
      str << output(names, dflt, "D ")

      str << "#{@dash * 11} Build Gems #{@dash   * 13} \n"
      str << output(names, build, "B ")
      
      str << "#{@dash * 11} User Gems #{@dash    * 14} \n"
      str << output(names, user, "U ")
      str
    end

    def gem_settings
      str = "\n#{@dash_line} Gem Settings\n".dup
      %w[ bindir default_dir default_rubygems_dirs default_spec_cache_dir dir path spec_cache_dir user_home user_dir ].each { |d|
        if Gem.respond_to?(d)
          str << "#{d.ljust(@first_col)}#{Gem.send(d.to_sym)}\n"
        else
          str << "#{d.ljust(@first_col)}not defined\n"
        end
      }
      "#{str}\n"
    end

    def path
      "#{@dash_line} Path\n#{ENV['PATH'].gsub(/\s*;+\s*/, "\n")}\n"
    end

    def ruby_info
      require 'rbconfig' unless defined? RbConfig
      str = "#{@dash_line} Ruby Info\n#{RUBY_DESCRIPTION}\n\n".dup
      gcc = RbConfig::CONFIG["CC_VERSION_MESSAGE"] ?
        RbConfig::CONFIG["CC_VERSION_MESSAGE"][/\A.+?\n/].strip : 'unknown'
      str << "       gcc info: #{gcc}\n\n"

      verify = ssl_verify
      str << first('openssl', 'OpenSSL::VERSION', 0) { OpenSSL::VERSION }
      str << additional('SSL Verify'             , 0, 4) { verify }
      str << additional('OPENSSL_VERSION'        , 0, 4) { OpenSSL::OPENSSL_VERSION }
      if OpenSSL.const_defined?(:OPENSSL_LIBRARY_VERSION)
        str << additional('OPENSSL_LIBRARY_VERSION', 0, 4) { OpenSSL::OPENSSL_LIBRARY_VERSION }
      else
        str << additional('OPENSSL_LIBRARY_VERSION', 0, 4) { "Not Defined" }
      end
      str << "\n#{ssl_methods}"
      str << additional('Available protocols', 0, 4) { TestSSL.check_supported_protocol_versions }
      str << "\n"

      str << additional_file('X509::DEFAULT_CERT_FILE'    , 0, 4) { OpenSSL::X509::DEFAULT_CERT_FILE }
      str << additional_file('X509::DEFAULT_CERT_DIR'     , 0, 4) { OpenSSL::X509::DEFAULT_CERT_DIR }
      str << additional_file('Config::DEFAULT_CONFIG_FILE', 0, 4) { OpenSSL::Config::DEFAULT_CONFIG_FILE }
      str << "\n"
      str << additional_file("ENV['SSL_CERT_FILE']"       , 0, 4) { ENV['SSL_CERT_FILE'] }
      str << additional_file("ENV['SSL_CERT_DIR']"        , 0, 4) { ENV['SSL_CERT_DIR']  }
      str << additional_file("ENV['OPENSSL_CONF']"        , 0, 4) { ENV['OPENSSL_CONF']  }
      str << "\n"

      str << first('rubygems'  , 'Gem::VERSION'  , 3)  { Gem::VERSION     }
      str << "\n"
      str << first('gdbm'      , 'GDBM::VERSION' , 3)  { GDBM::VERSION    }
      str << first('json/ext'  , 'JSON::VERSION' , 3)  { JSON::VERSION    }
      str << double('psych'    , 'Psych::VERSION', 'LIBYAML_VERSION', 3, 1, 2) { [Psych::VERSION, Psych::LIBYAML_VERSION] }
      begin
        require 'readline'
        @rl_type = (Readline.method(:line_buffer).source_location ? 'rb' : 'so')
        str << first('readline', "Readline::VERSION (#{@rl_type})", 3) { Readline::VERSION }
        str << double('zlib', 'Zlib::VERSION', 'ZLIB_VERSION', 3, 1, 2) { [Zlib::VERSION, Zlib::ZLIB_VERSION] }
      rescue LoadError
        str << "readline is unavailable\n"
      end

      if const_defined?(:Integer)
        str << ( Integer.const_defined?(:GMP_VERSION) ?
          "#{'Integer::GMP_VERSION'.ljust(@@col_wid[3])}#{Integer::GMP_VERSION}\n" :
          "#{'Integer::GMP_VERSION'.ljust(@@col_wid[3])}Unknown\n" )
      elsif const_defined?(:Bignum)
        str << ( Bignum.const_defined?(:GMP_VERSION) ?
          "#{'Bignum::GMP_VERSION'.ljust( @@col_wid[3])}#{Bignum::GMP_VERSION}\n" :
          "#{'Bignum::GMP_VERSION'.ljust( @@col_wid[3])}Unknown\n" )
      end
      str << "\n#{@dash * (@width - 10)} $LOAD_PATH\n#{$LOAD_PATH.join("\n")}\n"

#      str << "\n#{@dash * (@width - 10)} RbConfig\n"
#      str << rb_config
      str
    end

    def first(req, text, idx)
      col = idx > 10 ? idx : @@col_wid[idx]
      require req
      "#{text.ljust(col)}#{yield}\n"
    rescue LoadError
      "#{text.ljust(col)}NOT FOUND!\n"
    end

    def additional(text, idx, indent = 0)
      fn = yield
      "#{(' ' * indent + text).ljust(@@col_wid[idx])}#{fn}\n"
    rescue LoadError
      ""
    end

    def additional_file(text, idx, indent = 0)
      fn = yield
      if fn.nil?
        found = 'No ENV key'
      elsif /\./ =~ File.basename(fn)
        found = File.exist?(fn) ?
          "#{File.mtime(fn).utc.strftime('File Dated %F').ljust(23)}#{fn}" :
          "#{'File Not Found!'.ljust(23)}Unknown path or file"
      else
        found = Dir.exist?(fn) ?
          "#{'Dir  Exists'.ljust(23)}#{fn}" :
          "#{'Dir  Not Found!'.ljust(23)}Unknown path or file"
      end
      "#{(' ' * indent + text).ljust(@@col_wid[idx])}#{found}\n"
    rescue LoadError
      ""
    end

    def env_file_exists(env)
      if fn = ENV[env]
        if /\./ =~ File.basename(fn)
          "#{ File.exist?(fn) ? "#{File.mtime(fn).utc.strftime('File Dated %F')}" : 'File Not Found!      '}  #{fn}"
        else
          "#{(Dir.exist?(fn) ? 'Dir  Exists' : 'Dir  Not Found!').ljust(23)}  #{fn}"
        end
      else
        "none"
      end
    end

    def double(req, text1, text2, idx1, idx2, idx3)
      require req
      val1, val2 = yield
      "#{text1.ljust(@@col_wid[idx1])}#{val1.ljust(@@col_wid[idx2])}" \
        "#{text2.ljust(@@col_wid[idx3])}#{val2}\n"
    rescue LoadError
      "#{text1.ljust(@@col_wid[idx1])}NOT FOUND!\n"
    end

    def rb_config
      str = ''.dup
      %w[libdir rubylibprefix sitedir sitelibdir vendordir vendorlibdir].each { |k|
        dir = RbConfig::CONFIG[k]
        ex = Dir.exist?(dir) ? "ok     " : "missing"
        str << "#{k.ljust(16)}#{ex}  #{dir}\n"
      }
      "#{str}\n"
    end

    def ri2_vers
      require 'rbconfig' unless defined? RbConfig
      fn = "#{RbConfig::CONFIG['sitelibdir']}/ruby_installer/runtime/package_version.rb"
      if File.exist?(fn)
        s = File.read(fn)
        "RubyInstaller2 vers #{s[/^ *PACKAGE_VERSION *= *['"]([^'"]+)/, 1].strip}  commit #{s[/^ *GIT_COMMIT *= *['"]([^'"]+)/, 1].strip}"
      else
        "RubyInstaller build?"
      end
    end

    def ssl_methods
      ssl = OpenSSL::SSL
      if OpenSSL::VERSION < '2.1'
        additional('SSLContext::METHODS', 0, 4) {
          ssl::SSLContext::METHODS.reject { |e| /client|server/ =~ e }.sort.join(' ')
        }
      else
        additional('SSLContext versions', 0, 4) {
          ctx = OpenSSL::SSL::SSLContext.new
          if ctx.respond_to? :min_version=
            ssl_methods = []
            all_ssl_meths =
            [ [ssl::SSL2_VERSION  , 'SSL2'  ],
              [ssl::SSL3_VERSION  , 'SSL3'  ],
              [ssl::TLS1_VERSION  , 'TLS1'  ],
              [ssl::TLS1_1_VERSION, 'TLS1_1'],
              [ssl::TLS1_2_VERSION, 'TLS1_2']
            ]
            if defined? ssl::TLS1_3_VERSION
              all_ssl_meths << [ssl::TLS1_3_VERSION, 'TLS1_3']
            end
            all_ssl_meths.each { |m|
              begin
                ctx.min_version = m[0]
                ctx.max_version = m[0]
                ssl_methods << m[1]
              rescue
              end
            }
            ssl_methods.join(' ')
          else
            ''
          end
        }
      end
    end

    def ssl_verify
      t_st = Time.now
      require 'openssl'
      require 'net/http'
      uri = URI.parse('https://raw.githubusercontent.com/SketchUp/ruby-api-docs/gh-pages/css/common.css')

      ca_fn = if File.exist?(OpenSSL::X509::DEFAULT_CERT_FILE) 
          OpenSSL::X509::DEFAULT_CERT_FILE
        elsif File.exist?(ENV['SSL_CERT_FILE'])
          ENV['SSL_CERT_FILE']
        elsif RUBY_PLATFORM =~ /mswin|mingw/ && File.exist?('C:/Program Files/SketchUp/ssl/cert.pem')
          'C:/Program Files/SketchUp/ssl/cert.pem'
        end

      opts = {
        :use_ssl => true,
        :verify_mode => OpenSSL::SSL::VERIFY_PEER,
        :ca_file => ca_fn,
        :verify_depth => 5
      }
      ret = "*** FAILURE ***"
      Net::HTTP.start(uri.host, uri.port, opts) { |https|
        if Net::HTTPOK === https.get(uri.path)
          ret = "Success in #{sprintf("%5.3f", Time.now - t_st)} sec"
        end
      }
      ret
    rescue OpenSSL::SSL::SSLError
      "*** FAILURE ***"
    end

    def gem_setup
      require 'stringio' unless defined? StringIO
      # create streamUI with io
      sio_in, sio_out, sio_err = StringIO.new, StringIO.new, StringIO.new
      Gem::StreamUI.new(sio_in, sio_out, sio_err, false)
    end

    def gem_teardown(strm_io)
      strm_io.errs.close
      strm_io.ins.close
      strm_io.outs.close
      strm_io = nil
    end

    def help
      "Arguments (symbols, separate with commas)\n"     \
      "  :all          prints all the below (same as blank)\n" \
      "  :env\n"                                \
      "  :path\n"                               \
      "  :encodings\n"                          \
      "  :ruby_info    Ruby & std-lib info\n"   \
      "  :gem          prints all of the below" \
      "  :gem_settings various Gem attribute values\n" \
      "  :gem_env      same as `gem env`\n"     \
      "  :gem_list     same as `gem list`, also shows install locations\n"
    end

    # used by gem_list
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

    # used by gem_list
    def extract(names, spec_dir)
      gem_ary = Dir['*.gemspec', base: spec_dir]
      ary = []
      gem_ary.each do |fn| 
        full = fn.sub(/\.gemspec\z/, '').dup
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
      ary
    end

  end # class << self
end

SUInfo.run :ruby_info, :gem
