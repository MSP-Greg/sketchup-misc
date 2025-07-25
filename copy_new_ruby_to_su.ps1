<#

---------------------------
SketchUp.exe - Entry Point Not Found
---------------------------
rb_ary_detransient


must run in admin console

Code by MSP-Greg
Version 2024-3.2.5
#>

$is_admin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$is_admin) {
  Write-Host "Not running in Administrator mode, exiting..."
  exit
}

# modify the below lines setting $ruby, $su, and $vers to match your system

# where you placed the zip file folders
$ruby = 'C:/ruby-mswin-su-3.3.4'

if (!(Test-Path -Path $ruby/bin -PathType Container )) {
  echo "Extracted zip file folder $ruby/bin does not exist!`nPlease update ps1 file"
  exit
}

# the root folder of your copy of the SU 2024 files
$su = 'C:/Program Files/SketchUp/SketchUp 2024-3.3.4'

if (!(Test-Path -Path $su -PathType Container )) {
  echo "SketchUp copy at $su does not exist!`nPlease update ps1 file"
  exit
}

# The version of Ruby used, with the last number replaced by zero.
$vers    = '3.3.0'
$su_vers = '3.2.0'

$dll_vers = $su_vers.replace('.','')
$std_lib = 'Tools/RubyStdLib'

# copy main Ruby dll
Copy-Item -Path "$ruby/bin/x64-ucrt-ruby$dll_vers.dll" -Destination $su -Force

# clean Tools\RubyStdLib
if (Test-Path -Path "$su/$std_lib" -PathType Container ) {
  Remove-Item -Path "$su/$std_lib" -Recurse
}

# copy into Tools/RubyStdLib
Copy-Item "$ruby/lib/ruby/$vers" -Recurse -Destination "$su/$std_lib"

# copy cert.pem
Copy-Item "$ruby/bin/etc/ssl/cert.pem" -Destination "$su/Tools/cacert.pem"

# rename ext dir
Rename-Item -Path "$su/$std_lib/x64-mswin64_140" -NewName "$su/$std_lib/platform_specific"

# copy MSYS2 dlls
Copy-Item -Filter *.dll -Path "$ruby/bin/ruby_builtin_dlls/*" -Recurse -Destination  $su/$std_lib/platform_specific -Force

# clean Tools\RubyStdLib
if (Test-Path -Path "$su/Tools/gems/$vers" -PathType Container ) {
  Remove-Item -Path "$su/Tools/gems/$vers" -Recurse
}

# copy gems
Copy-Item "$ruby/lib/ruby/gems/$vers" -Recurse -Destination "$su/Tools/gems/$vers"
