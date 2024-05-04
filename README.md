# sketchup-misc

Miscellaneous code for use with SketchUp, and misc docs

The file `su_info.rb` outputs Ruby related information when loaded in SketchUp.  Tested with SU 2016 and later.

The file `ruby_info.rb` outputs Ruby related information for stand-alone Rubies.  It was designed to be used on 'fresh' Ruby builds of all platforms and OS's, so it shows additional information.

The file `su_gem.rb` wraps RubyGems' main object `Gem` in an `SUGem` object, allowing use of RubyGems in scripts or in SketchUp's Ruby Console.

Other files may be included that show various behaviors in SketchUp. Typically these show
issues related to the SketchUp Ruby API and its use in plugins/extensions.

I may force push to the repo, so please account for that when updating forks or clones.

```
git pull <remote name> main --rebase
```
