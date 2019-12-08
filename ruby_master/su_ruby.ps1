<#

must run in admin console

Code by MSP-Greg

#>

# modify the following three lines to match your system
# note that paths use forward slashes
$ruby = "C:/Ruby99-x64"
$su   = "C:/Program Files/SketchUp/SketchUp 2019_m"

# below stops script if not running in Admin shell
$is_admin = ([Security.Principal.WindowsPrincipal] `
  [Security.Principal.WindowsIdentity]::GetCurrent() `
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$is_admin) {
  Write-Host "Not running in Administrator mode, exiting..."
  exit
}

$vers    = &$ruby/bin/ruby.exe -e "STDOUT.write RbConfig::CONFIG['ruby_version']"
$std_lib = "Tools/RubyStdLib"

# copy main Ruby dll
Copy-Item -Path "$ruby\bin\x64-msvcrt-ruby270.dll" -Destination $su -Force

# copy MSYS2 dlls
Copy-Item -Filter *.dll -Path "$ruby\bin\ruby_builtin_dlls\*" -Recurse -Destination  $su -Force

# clean Tools\RubyStdLib
Remove-Item -Path "$su\$std_lib" -Recurse

# copy into Tools\RubyStdLib
Copy-Item "$ruby\lib\ruby\2.7.0" -Recurse -Destination "$su\$std_lib"

# copy cert.pem
Copy-Item "$ruby\ssl\cert.pem" -Destination "$su\..\ssl\cert.pem"
Copy-Item "$ruby\ssl\cert.pem" -Destination "$su\Tools\cacert.pem"

# rename ext dir
Rename-Item -Path "$su\$std_lib\x64-mingw32" -NewName "$su\$std_lib\platform_specific"

# following sets RubyGems info to use standard Ruby folders
$txt  = "ENV['GEM_HOME'] = `"$ruby/lib/ruby/gems/$vers`"`n"
$txt += "ENV['GEM_PATH'] = `"#{Gem.user_dir}`"`n"
$txt += "Gem.instance_variable_set(:@default_dir, '$ruby/lib/ruby/gems/$vers')`n"
$txt += "yr = RbConfig::TOPDIR[/\d{4}/]`n"
$txt += "repl = RbConfig::TOPDIR.sub('Tools', '').gsub('/', `"\\`")`n"
$txt += "ENV['PATH'] = ENV['PATH'].sub(`"#{ENV['ProgramFiles']}\\SketchUp\\SketchUp #{yr}\\;`", `"#{repl};`")`n"

# update rbconfig.rb
$rbconfig = Get-Content -Raw -Path "$su\$std_lib\platform_specific\rbconfig.rb" -Encoding UTF8
$rbconfig = $rbconfig.replace("/lib/ruby/$vers/x64-mingw32", "/RubyStdLib/platform_specific")

$UTF8 = $(New-Object System.Text.UTF8Encoding $False)

# write to operating_system.rb
[IO.File]::WriteAllText("$su/$std_lib/rubygems/defaults/operating_system.rb", $txt, $UTF8)

# write to rbconfig.rb
[IO.File]::WriteAllText("$su/$std_lib/platform_specific/rbconfig.rb", $rbconfig, $UTF8)
