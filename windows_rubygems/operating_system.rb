ENV['GEMRC'] = "#{RbConfig::TOPDIR}/.gemrc"
ENV['GEM_PATH'] = "#{RbConfig::TOPDIR}/lib/ruby/gems/#{RbConfig::CONFIG['ruby_version']}"
Gem.paths = ENV
