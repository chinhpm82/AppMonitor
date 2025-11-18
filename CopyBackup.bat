@echo off
setlocal enabledelayedexpansion

:: Setup folder
set "SOURCE1=build/libs"
set "SOURCE2=src/main/java/com/monitor
set "DEST_ROOT=backup"

:: Get system time with YYYYMMDD_hhmmss
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TIMESTAMP=%%a"

:: Create folder
set "DEST=%DEST_ROOT%\%TIMESTAMP%"
::set "DEST1=%DEST%"
set "DEST2=%DEST%"

::mkdir "%DEST1%"
mkdir "%DEST2%"

:: Backup data from SOURCE1
:: xcopy "%SOURCE1%\*" "%DEST1%\" /E /I /H /Y

:: Backup data from SOURCE2
xcopy "%SOURCE2%" "%DEST2%\" /I /H /Y
xcopy "start*" "%DEST2%\" /I /H /Y
xcopy "build.gradle" "%DEST2%\" /I /H /Y
xcopy "%SOURCE1%" "%DEST2%\" /I /H /Y

:: Backup run_hsm_app.bat
:: copy "run_hsm_app.bat" "%DEST1%\" /Y

echo Backup completed: %DEST%
pause