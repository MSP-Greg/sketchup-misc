# Use Ruby master in SketchUp

## General

Allows using/testing Ruby master in SketchUp on Windows.  At present, only SU 2019 is compatible with Ruby master.

Note that this creates a second SU install, so your original/standard SU 2019 is unaffected.  Also, you'll have a full, stand-alone Windows install of Ruby master.

Changes between Ruby versions (major.minor.teeny) can vary a great deal.  One thing that is standard is that the ABI (Application Binary Interface), which is the 'c' interface, remains compatible between major.minor versions.  For instance, any 'c' calls present in Ruby 2.6.0 will be available and unchanged for all subsequent versions of Ruby 2.6.

This is the reason that several folders and files in a standard Ruby install have 'major.minor.0' included in their name.

This also means that versions of Ruby released after the included SketchUp version may be incompatible.

## Requirements

1. Code editor

2. [7Zip](https://www.7-zip.org/download.html)

## Create the new SketchUp folder

First, copy the current SU 2019 folder (C:\Program Files\SketchUp\SketchUp 2019).  I normally name the folder C:\Program Files\SketchUp\SketchUp 2019_m.  Not that the new folder name must have the four year digits in it.

In the copy, there are two files that need to be edited:
```cmd
SketchUp.exe
LayOutRubyAPI.so
```

These files both contain one instance of the string `x64-msvcrt-ruby250.dll`.  The `250` needs to be changed to the Ruby version you'd like to install,  For example, change it to `270` for Ruby 2.7.0.  I've used Notepad++ for the editing.

Also, you can delete the file `x64-msvcrt-ruby250.dll`.

If you're using `SURubyDebugger.dll`, the same needs to be done for it.

## Install the new Ruby files.

Ruby master can be downloaded from the link:

https://ci.appveyor.com/api/projects/MSP-Greg/ruby-loco/artifacts/ruby_trunk.7z

After downloading it, you'll need to unzip it with 7Zip.  A common base folder name for 64 bit Rubies is `C:\Ruby27-x64`.

Since this is Ruby master, I normally place it in `C:\Ruby99-x64`, so any references I have to it will stay the same as the version changes.

Now, copy the file `ruby_master\su_ruby.ps1` to somewhere on your drive, modify lines 11 and 12  to match you system, then run it from a PowerShell console started in Admin mode, which is required to update any files in `C:\Program Files`.  Running it will also update the cert file used by newer SU versions.

Lines 11 and 12 currently use `C:\Ruby99-x64` for the stand-alone Ruby folder, and `C:\Program Files\SketchUp\SketchUp 2019_m` for the new SU2019 folder.  If that matches your system, no changes are needed.

After running it, typing `RUBY_DESCRIPTION` in the Ruby console should show the version of Ruby being used.

## Notes

1. All plugins are shared between your standard SU 2019 install and the Ruby master install.

2. The Ruby install that was unzipped is a fully functional Windows Ruby install.  Normally, one would add two items to `PATH`.
  
    ```
    C:\Ruby99-x64\bin
    C:\Users\<user name>\.gem\ruby\2.7.0\bin
    ```

3. All gems are shared between the unzipped stand-alone Ruby install and the SU one.  No gems are shared between this install and the standard 2019 install.

4. Because of #3, I normally install gems with `--user-install`, so updating the stand-alone Ruby install does not overwrite them.

    To do so from stand-alone Ruby, use:
    ```cmd
    gem install <gems, versions, etc> --user-install
    ```
  
    Within the SU Ruby console:
    ```ruby
    Gem.install(<gems, versions, etc>, :user_install => true)
    ```

5. A utility to show info about the Ruby master version is included in this folder.  To run it, load it in the SU console.  It can output more information, see the `help` method, or, after loading it, use `SUInfo.run :help`.
