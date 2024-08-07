## Instructions for updating Ruby installation in SketchUp 2024

### 1. Download the following files:

https://raw.githubusercontent.com/MSP-Greg/sketchup-misc/main/copy_new_ruby_to_su.ps1 (right-click, then 'Save as')


https://github.com/MSP-Greg/sketchup-misc/releases/download/v0.0.0/ruby-mswin-su-3.2.5.zip

### 2. Copy your Sketchup 2024 install folder

A simple Ctrl-C and Ctrl-V when on the folder C:/Program Files/SketchUp/SketchUp 2024.  Then, rename it 'SketchUp 2024-3.2.5'

### 3. Unzip the Ruby zip file

The Powershell script assumes it's located at 'C:/ruby-mswin-su-3.2.5'. After it's unzipped, typing `C:/ruby-mswin-su-3.2.5/bin/ruby -v` should show the Ruby version.

### 4. Run the Powershell script from an 'Admin' Powershell window.

The Powershell script has the above paths on lines 21 and 28.  Change the script if you want to use different folders.

### You're finished

You now have stand-alone Ruby install and an updated SU 2024.  Typing `RUBY_DESCRIPTION` in the SU Ruby console should show:
```
ruby 3.2.5 (2024-07-26 revision 31d0f1a2e7) [x64-mswin64_140]
```
