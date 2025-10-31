@echo off
setlocal

set "extra_flags="
set source_path=source
set exe_path=.\app.exe
set can_package_include=1
set parin_package_path=.\parin_package
set compiler=dmd
set version=windows_x86_64

if not "%~1"=="" set compiler=%~1
if not "%~2"=="" set version=%~2

rem Find the source folder.
set app_path=%source_path%\app.d
if not exist "%source_path%\" (
    set source_path=src
    set app_path=%source_path%\app.d
)
if not exist "%source_path%\" (
    set source_path=.
    set app_path=%source_path%\app.d
)

rem Include from packages if needed.
set "package_include="
if "%can_package_include%"=="1" (
    if not exist "%source_path%\parin\" (
        set "package_include=-I=%parin_package_path%\source"
        echo Building with: %package_include%
    )
)

%compiler% ^
    -of=%exe_path% -i ^
    -L=/LIBPATH:%parin_package_path%\vendor\%version% ^
    -J=%parin_package_path%\source\parin -J=.\assets ^
    -I=%source_path% %package_include% ^
    %extra_flags% -run %app_path%

endlocal
