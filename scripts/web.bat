@echo off
setlocal

set app_path=.\app.d
set parin_package_path=.\parin_package
set joka_package_path=.\joka_package

ldc2 -J=%parin_package_path%\packages\web\source -run %parin_package_path%\packages\web\source\app.d

endlocal
