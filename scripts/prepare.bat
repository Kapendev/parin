@echo off
setlocal

set app_path=.\app.d
set parin_package_path=.\parin_package
set joka_package_path=.\joka_package

git clone --depth 1 https://github.com/Kapendev/parin %parin_package_path%
git clone --depth 1 https://github.com/Kapendev/joka %joka_package_path%
xcopy %parin_package_path%\source\parin .\parin /E /I /Y
xcopy %joka_package_path%\source\joka .\joka /E /I /Y
copy %parin_package_path%\examples\basics\_001_hello.d %app_path%
copy %parin_package_path%\vendor\windows_x86_64\*.dll .\

endlocal
