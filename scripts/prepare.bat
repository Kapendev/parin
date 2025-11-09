@echo off
setlocal

set app_path=.\app.d
set parin_package_path=.\parin_package

rem git clone --depth 1 https://github.com/Kapendev/parin %parin_package_path%
xcopy %parin_package_path%\source\parin .\parin /E /I /Y
copy %parin_package_path%\examples\basics\_001_hello.d %app_path%
copy %parin_package_path%\packages\setup\source\vendor\windows_x86_64\* .\
mkdir .\assets

endlocal
