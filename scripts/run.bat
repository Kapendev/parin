@echo off
setlocal

set exe_path=.\app.exe
set app_path=.\app.d
set parin_package_path=.\parin_package
set joka_package_path=.\joka_package
set version=windows_x86_64
set compiler=ldc2
set "extra_flags="

if not "%~1"=="" set compiler=%~1
%compiler% ^
    -of=%exe_path% ^
    -L=-L%parin_package_path%\vendor\%version% ^
    -J=parin -i %extra_flags% ^
    -run %app_path%

endlocal
