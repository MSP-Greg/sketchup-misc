# sketchup-misc / windows_rubygems

This is brief overview of getting a better RubyGems experience with Windows SketchUp, versions 2022 and/or 2023.

You need some of the code contained in this repo.  You can clone/fork it using Git, or you can download a static copy with the following URI:

https://github.com/MSP-Greg/sketchup-misc/archive/refs/heads/main.zip

Instructions for setting up RubyGems are contained in the file:

`windows_rubygems/Windows RubyGems Update Instructions.txt`

A file in the root directory `su_gem.rb`, is a RubyGems helper file.  The file contains comments about its use.  Normally, RubyGems is used from the command line or called by Bundler.  The file creates an object `SUGem`, and it closely mimics the commmand line syntax.

It has an addition command/method, `SUGem.su_list`, which will show info on all the gems
available to SketchUp.  This includes several categories/locations.

Installing a gem is as simple as `SUGem.install 'rubyzip'`.

At present, what's referred to as 'bundled gems' are not included in the SketchUp Windows build.  The included directions will do that, along with configuring RubyGems correctly.

RubyGems will look for a file `.gemrc` and use it for additional configuration.  When using SketchUp, it will find the file in a location shared with stand-alone Rubies.  The included directions add a `.gemrc` file, and allow SketchUp's RubyGems to find it.  The new file disables document generation (RDoc & RI) for installed/updated gems.

SketchUp Windows Ruby also does not have RDoc installed.  At present, RDoc is considered a 'default gem', and is needed by RubyGems.  Instructions for adding RDoc are included.  Not doing so will result in an error when one tries to uninstall a gem.

Lastly, the RubyGems version included with RUby 2.7 is very slow.  A lot of code has been revised in newer versions, and I pushed the current version (compatible with Ruby 2.6 and later) into SketchUp, and it was much faster when installing gems.