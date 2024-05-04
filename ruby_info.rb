# frozen_string_literal: true
# encoding: UTF-8

# Copyright (C) 2017-2022 MSP-Greg

require 'rbconfig' unless defined? RbConfig
require 'tmpdir'
require 'etc'

module VersInfo

  SIGNAL_LIST = Signal.list.keys.sort

  if IO === $stdout
    YELLOW = "\e[38;2;223;223;16m"  # YELLOW = "\e[33m"
    RESET  = "\e[0m"
  else
    YELLOW = ''
    RESET  = ''
  end

  BIN_DIR = RbConfig::CONFIG['bindir']

  COL_WIDTH = [34, 14, 17, 26, 10, 16]

  WIN = !!RUBY_PLATFORM[/mingw|mswin/]

  # some fonts render \u2015 as a solid, other not...
  DASH = case ARGV[0]
  when 'utf-8'
    "\u2500".dup.force_encoding 'utf-8'
  when 'Windows-1252'
    151.chr
  else
    "\u2500".dup.force_encoding 'utf-8'
  end.freeze

  class << self

    def run
      puts ''
      puts   "     Etc.nprocessors: #{Etc.nprocessors}" if Etc.respond_to?(:nprocessors)
      if (np = ENV['NUMBER_OF_PROCESSORS'])
        puts "NUMBER_OF_PROCESSORS: #{np}"
      end
      puts   "          Dir.tmpdir: #{Dir.tmpdir}"
      if (rt = ENV['RUNNER_TEMP'])
        puts "         RUNNER_TEMP: #{rt}"
      end
      puts ""

      highlight "#{RUBY_DESCRIPTION}"
      puts
      puts "RUBY_ENGINE:         #{defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'nil'}\n" \
           "RUBY_ENGINE_VERSION: #{defined?(RUBY_ENGINE_VERSION) ? RUBY_ENGINE_VERSION : 'nil'}\n" \
           "RUBY_PLATFORM:       #{RUBY_PLATFORM}\n" \
           "RUBY_PATCHLEVEL:     #{RUBY_PATCHLEVEL}", ''
      puts " Build Type/Info: #{ri2_vers}\n" if WIN
      if (gcc = RbConfig::CONFIG["CC_VERSION_MESSAGE"])
        puts "        gcc info: #{gcc[/\A.+?\n/].strip}"
      end
      puts "RbConfig::TOPDIR: #{RbConfig::TOPDIR}\n\n" \
           "RbConfig::CONFIG['LIBRUBY_SO']:     #{RbConfig::CONFIG['LIBRUBY_SO']}\n" \
           "RbConfig::CONFIG['LIBRUBY_SONAME']: #{RbConfig::CONFIG['LIBRUBY_SONAME'] || 'nil'}\n" \
           "RbConfig::CONFIG['ruby_version']:   #{RbConfig::CONFIG['ruby_version']}\n" \
           "RbConfig::CONFIG['DLEXT']:          #{RbConfig::CONFIG['DLEXT']}\n" \
           "RbConfig::CONFIG['host_os']:        #{RbConfig::CONFIG['host_os']}"
      puts

      puts "RbConfig::CONFIG['configure_args']:"
      ary = RbConfig::CONFIG['configure_args'].strip.split(/ '?--/)
        .map { |e| e =~ /\A'?--/ ? e : "--#{e}" }
        .map { |e| (e.end_with?("'") && !e.start_with?("'")) ? e.sub("--", "'--") : e }
        .map { |e| "  #{e}" }
      puts(*ary)
      puts

      first('rubygems'  , 'Gem::VERSION'    , 2)  { Gem::VERSION      }
      first('bundler'   , 'Bundler::VERSION', 2)  { Bundler::VERSION }

      puts
      first('bigdecimal', 'BigDecimal.ver', 2)  {
        BigDecimal.const_defined?(:VERSION) ? BigDecimal::VERSION : BigDecimal.ver
      }
      first('gdbm'      , 'GDBM::VERSION' , 2)  { GDBM::VERSION    }
      first('json/ext'  , 'JSON::VERSION' , 2)  { JSON::VERSION    }
      puts

      openssl_conf = ENV.delete 'OPENSSL_CONF'

      if first('openssl', 'OpenSSL::VERSION', 0) { OpenSSL::VERSION }
        additional('SSL Verify'             , 0, 4) { ssl_verify }
        additional('OPENSSL_VERSION'        , 0, 4) { OpenSSL::OPENSSL_VERSION }
        if OpenSSL.const_defined?(:OPENSSL_LIBRARY_VERSION)
          additional('OPENSSL_LIBRARY_VERSION', 0, 4) { OpenSSL::OPENSSL_LIBRARY_VERSION }
        else
          additional('OPENSSL_LIBRARY_VERSION', 0, 4) { "Not Defined" }
        end
        ssl_methods
        puts
        additional_file('X509::DEFAULT_CERT_FILE'    , 0, 4) { OpenSSL::X509::DEFAULT_CERT_FILE }
        additional_file('X509::DEFAULT_CERT_DIR'     , 0, 4) { OpenSSL::X509::DEFAULT_CERT_DIR }
        unless RUBY_PLATFORM == 'java'
          additional_file('Config::DEFAULT_CONFIG_FILE', 0, 4) { OpenSSL::Config::DEFAULT_CONFIG_FILE }
        end
        puts
        additional_file("ENV['SSL_CERT_FILE']"       , 0, 4) { ENV['SSL_CERT_FILE'] }
        additional_file("ENV['SSL_CERT_DIR']"        , 0, 4) { ENV['SSL_CERT_DIR' ] }
        ENV['OPENSSL_CONF'] = openssl_conf if openssl_conf
        additional_file("ENV['OPENSSL_CONF']"        , 0, 4) { ENV['OPENSSL_CONF' ] }
      end
      puts

      double('psych', 'Psych::VERSION', 'LIBYAML_VERSION', 3, 1, 2) { [Psych::VERSION, Psych::LIBYAML_VERSION] }
      begin
        require 'readline'
        @rl_type = (Readline.method(:line_buffer).source_location ? 'rb' : 'so')
        first('readline', "Readline::VERSION (#{@rl_type})", 3) { Readline::VERSION }
      rescue LoadError
      end
      double('zlib', 'Zlib::VERSION', 'ZLIB_VERSION', 3, 1, 2) { [Zlib::VERSION, Zlib::ZLIB_VERSION] }

      if const_defined?(:Integer)
        puts Integer.const_defined?(:GMP_VERSION) ?
          "#{'Integer::GMP_VERSION'.ljust(COL_WIDTH[3])}#{Integer::GMP_VERSION}" :
          "#{'Integer::GMP_VERSION'.ljust(COL_WIDTH[3])}Unknown"
      elsif const_defined?(:Bignum)
        puts Bignum.const_defined?(:GMP_VERSION) ?
          "#{'Bignum::GMP_VERSION'.ljust( COL_WIDTH[3])}#{Bignum::GMP_VERSION}" :
          "#{'Bignum::GMP_VERSION'.ljust( COL_WIDTH[3])}Unknown"
      end

      puts '', "Available signals:"
      if SIGNAL_LIST.length > 13
        puts "  #{SIGNAL_LIST.select { |s| s <  'K' }.map { |s| s.ljust 7 }.join}",
             "  #{SIGNAL_LIST.select { |s| s >= 'K' && s < 'TT'}.map { |s| s.ljust 7 }.join}",
             "  #{SIGNAL_LIST.select { |s| s >= 'TT'}.map { |s| s.ljust 7 }.join}"
      else
        puts "  #{SIGNAL_LIST.map { |s| s.ljust 7 }.join}"
      end

      str = "\n#{DASH * 5} CLI Test #{DASH * 17}    #{DASH * 6} Require Test #{DASH * 6}"
      if WIN
        highlight "#{str}     #{DASH * 5} Require Test #{DASH * 5}"
      else
        highlight str
      end

      re_version = '(\d{1,2}\.\d{1,2}\.\d{1,2}(\.[a-z0-9.]+)?)'

      puts chk_cli("bundle -v",      /\ABundler version #{re_version}/) +
        loads('dbm'    , 'DBM'    , 'win32/registry', 'Win32::Registry')

      puts chk_cli("gem --version",  /\A#{re_version}/) +
        loads('debug'  , 'Debug'  , 'win32ole'      , 'WIN32OLE')

      puts chk_cli("irb --version",  /\Airb +#{re_version}/) +
        loads('digest' , 'Digest')
      puts chk_cli("racc --version", /\Aracc version #{re_version}/) +
        loads('fiddle' , 'Fiddle')
      puts chk_cli("rake -V", /\Arake, version #{re_version}/) +
        loads('socket' , 'Socket')
      puts chk_cli("rbs -v" , /\Arbs #{re_version}/)
      puts chk_cli("rdbg -v", /\Ardbg #{re_version}/)
      puts chk_cli("rdoc -v", /\A#{re_version}/)

      gem_list
    end

    private

    def ri2_vers
      fn = "#{RbConfig::TOPDIR}/lib/ruby/site_ruby/#{RbConfig::CONFIG['ruby_version']}/ruby_installer/runtime/package_version.rb"
      if File.exist?(fn)
        s = File.read(fn)
        "RubyInstaller2 vers #{s[/^ *PACKAGE_VERSION *= *['"]([^'"]+)/, 1].strip}  commit #{s[/^ *GIT_COMMIT *= *['"]([^'"]+)/, 1].strip}"
      elsif RUBY_PLATFORM[/mingw/]
        'RubyInstaller build?'
      else
        'NA'
      end
    end

    def loads(req1, str1, req2 = nil, str2 = nil)
      wid1 = 30
      wid2 = 11
      wid3 = 15
      begin
        if (req1 == 'dbm'   && RUBY_VERSION > '3.1') ||
           (req1 == 'debug' && RUBY_VERSION < '3.0')
          str = "#{str1.ljust wid2}  na".ljust(wid1+1)
        else
          require req1
          str = ("#{str1.ljust wid2}  " +
            ((WIN && RUBY_VERSION < '3.1' && req1 == 'debug') ? 'na' : '✅')).ljust wid1
        end
      rescue LoadError
        str = "#{str1.ljust wid2}  ❌ LoadError".ljust wid1
      rescue => e
        str = "#{str1.ljust wid2}  #{e.class}".ljust wid1
      end
      if req2 && (WIN || !req2[/\Awin32/])
        begin
          require req2
          str + "#{str2.ljust wid3} ✅"
        rescue LoadError
          str + "#{str2.ljust wid3} ❌ LoadError"
        end
      else
        str.strip
      end
    end

    def first(req, text, idx)
      col = idx > 10 ? idx : COL_WIDTH[idx]
      require req
      puts "#{text.ljust(col)}#{yield}"
      true
    rescue LoadError
      puts "#{text.ljust(col)}NOT FOUND!"
      false
    end

    def additional(text, idx, indent = 0)
      fn = yield
      puts "#{(' ' * indent + text).ljust(COL_WIDTH[idx])}#{fn}"
    rescue LoadError
    end

    def additional_file(text, idx, indent = 0)
      fn = yield
      if fn.nil?
        found = 'No ENV key'
      else
        disp_fn = fn
        disp_fn = disp_fn.sub "#{RbConfig::TOPDIR}/", '' if fn && fn.length > 34

        if /\./ =~ File.basename(fn)
          found = File.exist?(fn) ?
            "#{File.mtime(fn).utc.strftime('File Dated %F').ljust(23)}#{disp_fn}" :
            "#{'File Not Found!'.ljust(23)}#{fn}"
        elsif Dir.exist? fn
          found = "#{'Dir  Exists'.ljust(23)}#{disp_fn}\n".dup
          unless fn == (t = File.realpath(fn))
            found << "#{' ' * COL_WIDTH[idx]}#{'Dir  realpath'.ljust(23)}#{t}\n"
          end
        else
          found = "#{'Dir  Not Found!'.ljust(23)}#{fn}"
        end
      end
      puts "#{(' ' * indent + text).ljust(COL_WIDTH[idx])}#{found}"
    rescue LoadError
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
      puts "#{text1.ljust(COL_WIDTH[idx1])}#{val1.ljust(COL_WIDTH[idx2])}" \
           "#{text2.ljust(COL_WIDTH[idx3])}#{val2}"
    rescue LoadError
      puts "#{text1.ljust(COL_WIDTH[idx1])}NOT FOUND!"
    end

    def gem_list
      name_wid = 24
      ary_default = []
      ary_bundled = []

      ruby_gems = Gem.default_dir.start_with?(RbConfig::TOPDIR) ?
        Gem.default_dir : Gem.dir

      Gem::Specification.each { |s|
        if s.spec_dir.start_with? ruby_gems
          if s.default_gem?
            ary_default << [s.name, s.version.to_s]
          else
            ary_bundled << [s.name, s.version.to_s]
          end
        end
      }
      ary_default.sort_by! { |a| a[0] }
      ary_bundled.sort_by! { |a| a[0] }

      return if ary_default.empty? && ary_bundled.empty?

      highlight "\n#{DASH * 23} #{"Default Gems #{DASH * 5}".ljust(name_wid)} #{DASH * 23} Bundled Gems #{DASH * 5}"

      max_rows = [ary_default.length || 0, ary_bundled.length || 0].max

      (0..(max_rows-1)).each { |i|
        dflt = ary_default[i] ? ary_default[i] : ["", "", 0]
        bndl = ary_bundled[i] ? ary_bundled[i] : nil

        str_dflt = "#{dflt[1].rjust(23)} #{dflt[0].ljust(name_wid)}"
        str_bndl = bndl ? "#{bndl[1].rjust(23)} #{bndl[0]}" : ''

        puts bndl ? "#{str_dflt} #{str_bndl}".rstrip : "#{str_dflt}".rstrip
      }
      puts ''
    end

    def ssl_methods
      ssl = OpenSSL::SSL
      if RUBY_VERSION < '2.0'
        additional('SSLContext::METHODS', 0, 4) {
          ssl::SSLContext::METHODS.reject { |e| /client|server/ =~ e }.sort.join(' ')
        }
      else
        require_relative 'ruby_info/ssl_test'
        additional('Available Protocols', 0, 4) {
          TestSSL.check_supported_protocol_versions
        }
      end
    end

    def ssl_verify
      require 'net/http'
      uri = URI.parse('https://raw.githubusercontent.com/gcc-mirror/gcc/master/config.guess')
      Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_PEER) { |https|
        Net::HTTP::Get.new uri
      }
      "Success"
    rescue SocketError
      "*** UNKNOWN - internet connection failure? ***"
    rescue OpenSSL::SSL::SSLError # => e
      "*** FAILURE ***"
    end

    def chk_cli(cmd, regex)
      wid = 36
      return 'rbs       na'.ljust(wid) if cmd.start_with?('rbs')  && RUBY_VERSION < '3'
      return 'rdbg      na'.ljust(wid) if cmd.start_with?('rdbg') && RUBY_VERSION < '3.1'

      cmd_str = cmd[/\A[^ ]+/].ljust(10)
      if File.exist? "#{BIN_DIR}/#{cmd_str}".strip
        require 'open3'
        ret = ''.dup
        Open3.popen3(cmd) {|stdin, stdout, stderr, wait_thr|
          ret = stdout.read.strip
        }
        if ret[regex]
          "#{cmd_str}✅   #{$1}".ljust(wid)
        else
          "#{cmd_str}❌   version?".ljust(wid)
        end
      else
        "#{cmd_str}❌   missing binstub".ljust(wid)
      end
    rescue => e
      "#{cmd_str}❌   #{e.class}".ljust(wid)
    end

    def highlight(str)
      str2 = str.dup
      while str2.sub!(/\A\n/, '') do ; puts ; end
      puts "#{YELLOW}#{str2}#{RESET}"
    end

  end
end

VersInfo.run
exit 0 if IO === $stdout
