@echo off
setlocal

set "extra_flags="
set source_path=.
set app_path=%source_path%\app.d
set exe_path=.\app.exe
set parin_package_path=.\parin_package
set joka_package_path=.\joka_package
set compiler=dmd
set version=windows_x86_64

if not "%~1"=="" set compiler=%~1
if not "%~2"=="" set version=%~2
%compiler% ^
    -of=%exe_path% ^
    -L=-L%parin_package_path%\vendor\%version% ^
    -J=%parin_package_path%\source\parin -I=%source_path% -i %extra_flags% ^
    -run %app_path%

endlocal
