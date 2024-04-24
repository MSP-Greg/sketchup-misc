<#

must run in admin console

Code by MSP-Greg
Version 2024-3.2.4
#>

$is_admin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$is_admin) {
  Write-Host "Not running in Administrator mode, exiting..."
  exit
}

# modify the following three lines to match your system and Ruby version
# note that paths use forward slashes

# where you placed the zip file folders
$ruby = "C:/ruby-mswin-su-3.2.4"
# the root folder of your copy of the SU 2024 files
$su   = "C:/Program Files/SketchUp/SketchUp 2024-3.2.4"
# The version of Ruby used, with the last number replaced by zero.
$vers = "3.2.0"

$dll_vers = $vers.replace('.','')
$std_lib = "Tools/RubyStdLib"

# copy main Ruby dll
Copy-Item -Path "$ruby\bin\x64-ucrt-ruby$dll_vers.dll" -Destination $su -Force

# clean Tools\RubyStdLib
Remove-Item -Path "$su\$std_lib" -Recurse

# copy into Tools/RubyStdLib
Copy-Item "$ruby/lib/ruby/$vers" -Recurse -Destination "$su\$std_lib"

# copy cert.pem
Copy-Item "$ruby/bin/etc/ssl/cert.pem" -Destination "$su/Tools/cacert.pem"

# rename ext dir
Rename-Item -Path "$su/$std_lib/x64-mswin64_140" -NewName "$su/$std_lib/platform_specific"

# copy MSYS2 dlls
Copy-Item -Filter *.dll -Path "$ruby/bin/ruby_builtin_dlls/*" -Recurse -Destination  $su/$std_lib/platform_specific -Force

# clean Tools\RubyStdLib
Remove-Item -Path "$su/Tools/gems/$vers" -Recurse

# copy gems
Copy-Item "$ruby/lib/ruby/gems/$vers" -Recurse -Destination "$su/Tools/gems/$vers"
