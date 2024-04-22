# sketchup-misc

Miscellaneous code for use with SketchUp, and misc docs

The file `su_info.rb` outputs Ruby related information when loaded.  Tested with SU 2016 and later.

Other files exist that show various behaviors in SketchUp. Typically these show
issues related to the SketchUp Ruby API and its use in plugins/extensions.

The file `su_gem.rb` wraps RubyGems' main object `Gem` in an `SUGem` object, allowing use of RUbyGems in scripts or in SketchUp's Ruby Console.

The folder `windows_rubygems` contains files and information about improving the Windows RubyGems installation & adding the standard bundled gems included with Ruby.

I may force push to the repo, so please account for that when updating forks or clones.

```
git pull <remote name> main --rebase
```
