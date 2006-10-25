rem Robocopy is part of the W2K3 Resource Kit and can mirror a folder
rem More info: http://www.ss64.com/nt/robocopyXP.html

@echo off
cls
title Robocopy advies 1.0.000

SETLOCAL
set error=false
set robocopy_fileset=robocopy_fileset.csv

rem Check whether Robocopy exist
if NOT exist robocopy.exe echo Error: Robocopy.exe missing. & set error=true & goto :end

rem Check whether the settings file exist
if NOT exist %robocopy_fileset% echo Error: Settings file (%robocopy_fileset%) does not exist. & set error=true & goto :end

rem This sections reads the settings from %robocopy_fileset%
rem The subroutine :robocopy is called for each line
for /F "skip=1 tokens=1,2,3,4 delims=;" %%i in (%robocopy_fileset%) do (set sourcefolder=%%i) & (set destinationfolder=%%j) & (set excludefolders=%%k) & (set excludefiles=%%l) & call :robocopy

rem If this line in the script is reached the complete %robocopy_fileset% is done
goto :end

:robocopy
rem Strip trailing backslash from source and destination directories if there is one.
rem Otherwise Robocopy will fail...
if "%sourcefolder:~-1%" == "\" set sourcefolder="%sourcefolder:~0,-1%"
if "%destinationfolder:~-1%" == "\" set destinationfolder="%destinationfolder:~0,-1%"

rem Check whether the sourcefolder exists
if NOT exist %sourcefolder% echo Error: Source (%sourcefolder%) does not exist. & set error=true & goto :eof

rem Output read options to screen
echo Robocopy is busy mirroring (source -^> destination)...
echo * %sourcefolder% -^> %destinationfolder%
if NOT "%excludefolders%"=="" echo - Folders to exclude: %excludefolders%
if NOT "%excludefiles%"=="" echo - File(type)s to exclude: %excludefiles%

rem Extra parameters explained
rem /MIR
rem MIRror a directory tree - equivalent to /PURGE plus all subfolders (/E)
rem Unfortunatly Robocopy will not delete folders which have later been configured to ignore,
rem unless they've been removed from the network.
rem /ZB
rem Use restartable mode (survive network glitch); if access denied use Backup mode.
rem /NP
rem No progress (since output is logged to a logfile)
robocopy "%sourcefolder%" "%destinationfolder%" /XD %excludefolders% /XF %excludefiles% /MIR /ZB /NP /LOG:%robocopy_fileset%.log.txt
if %errorlevel%==16 echo Error: Roboform exit code 16 (FATAL ERROR). & echo Double backslash in "%robocopy_fileset%"? & set error=true & goto :eof
echo.

rem Exit the loop :Robocopy
goto :eof

:end
echo.
echo Finished Robocopy script.
if %error%==true color 4f & echo Unfortunatly something(s) went wrong. & echo If this screen output is not sufficient please check the logfile at: &echo "%cd%\%robocopy_fileset%.log.txt"
if %error%==false color 2f & echo Everything went fine.

echo.
echo Press any key to close this screen.
PAUSE > nul

ENDLOCAL