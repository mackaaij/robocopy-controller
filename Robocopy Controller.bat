@echo off
cls
SETLOCAL

set scriptversion=Robocopy Controller 1.1.000

set robocopy_fileset=robocopy_fileset.csv
set rebuild-list=rebuild-list.txt
set logfile=%temp%\%robocopy_fileset%.log.txt
set error=false

rem Create a new logfile
echo Start %scriptversion% > %logfile%

rem Set windowtitle of DOS box
title %scriptversion%

rem Check whether Robocopy exist
if NOT exist robocopy.exe set error=Error: Robocopy.exe missing. & goto :end

rem Check whether the settings file exist
if NOT exist "%robocopy_fileset%" set error=Error: Settings file ("%robocopy_fileset%") does not exist. & goto :end

rem Pick op basetarget of fileset (if not found abort, malformed fileset)
findstr /I "basetarget" "%robocopy_fileset%" > nul
if NOT %errorlevel%==0 set error=Error: Settings file ("%robocopy_fileset%") does not contain a base target. & goto :end
for /F "tokens=2 delims=;" %%i in ('findstr /I "basetarget" "%robocopy_fileset%"') do set basetarget=%%i
echo Using base target %basetarget% of "%robocopy_fileset%" >> %logfile%

rem Pick op current version of fileset (if not found abort, malformed fileset)
findstr /I "filesetversion" "%robocopy_fileset%" > nul
if NOT %errorlevel%==0 set error=Error: Settings file ("%robocopy_fileset%") does not contain a version number. & goto :end
for /F "tokens=2 delims=;" %%i in ('findstr /I "filesetversion" "%robocopy_fileset%"') do set filesetversion=%%i
echo Using fileset version %filesetversion% of "%robocopy_fileset%" >> %logfile%

rem Check current filesetversion on target
rem First check if a version file exists otherwise goto :readfileset
if NOT exist "%basetarget%\*.filesetversion.txt" goto :readfileset
for /F %%i in ('dir "%basetarget%\*.filesetversion.txt" /b /od') do set versionfilename=%%i
set currentversion=%versionfilename:.filesetversion.txt=%

rem Check if current version is on the rebuild-list
rem (rebuild-listed versions require a delete of the target folder)
findstr /I "%currentversion%" "%rebuild-list%" > nul
if %errorlevel%==0 echo Deleting basetarget (%basetarget%) for complete rebuild. & echo. & echo Deleting basetarget (%basetarget%) for complete rebuild. >> %logfile% & echo. >> %logfile%

rem TODO: Steal attrib -s -h and rmdir commands from pc1218

:readfileset
rem This sections reads the settings from %robocopy_fileset%
rem The subroutine :robocopy is called for each line
for /F "skip=3 tokens=1,2,3,4 delims=;" %%i in ('type "%robocopy_fileset%"') do (set sourcefolder=%%i) & (set destinationfolder=%%j) & (set excludefolders=%%k) & (set excludefiles=%%l) & call :robocopy

rem If this line in the script is reached the complete %robocopy_fileset% is done
goto :end

:robocopy
rem Strip trailing backslash from source and destination directories if there is one.
rem Otherwise Robocopy will fail...
if "%sourcefolder:~-1%" == "\" set sourcefolder="%sourcefolder:~0,-1%"
if "%destinationfolder:~-1%" == "\" set destinationfolder="%destinationfolder:~0,-1%"

rem Check whether the sourcefolder exists
if NOT exist %sourcefolder% set error=Error: Source (%sourcefolder%) does not exist. & goto :eof

rem Output read options to screen
echo Robocopy is busy mirroring (source -^> destination)...
echo * %sourcefolder% -^> %destinationfolder%
if NOT "%excludefolders%"=="" echo - Folders to exclude: %excludefolders%
if NOT "%excludefiles%"=="" echo - File(type)s to exclude: %excludefiles%

rem Output read options to log
echo Robocopy is busy mirroring (source -^> destination)... >> %logfile%
echo * %sourcefolder% -^> %destinationfolder% >> %logfile%
if NOT "%excludefolders%"=="" echo - Folders to exclude: %excludefolders% >> %logfile%
if NOT "%excludefiles%"=="" echo - File(type)s to exclude: %excludefiles% >> %logfile%

rem Extra parameters explained
rem /MIR
rem MIRror a directory tree - equivalent to /PURGE plus all subfolders (/E)
rem Unfortunatly Robocopy will not delete folders which have later been configured to ignore,
rem unless they've been removed from the network.
rem /ZB
rem Use restartable mode (survive network glitch); if access denied use Backup mode.
rem /NP
rem No progress (since output is logged to a logfile)
rem /LOG+
rem Append logfile (if multiple folders are mirrored every log is contained)
robocopy "%sourcefolder%" "%destinationfolder%" /XD %excludefolders% /XF %excludefiles% /MIR /ZB /NP /LOG+:"%logfile%"
if %errorlevel%==16 set error=Error: Roboform exit code 16 (wrong "%robocopy_fileset%")? & goto :eof
echo.

rem Exit the loop :Robocopy
goto :eof

:end
rem Output results to screen
echo.
echo Finished Robocopy script.
if NOT "%error%"=="false" color 4f & echo. & echo Unfortunatly something(s) went wrong. & echo %error% & echo. & echo If this screen output is not sufficient please check the logfile at: & echo "%logfile%"
if "%error%"=="false" color 2f & echo Everything went fine.

rem Output results to log
echo. >> %logfile%
echo Finished Robocopy script. >> %logfile%
if NOT "%error%"=="false" color 4f & echo.  >> %logfile% & echo Unfortunatly something(s) went wrong.  > %logfile% & echo %error%  >> %logfile% & echo.  >> %logfile% & echo If this screen output is not sufficient please check the logfile at:  >> %logfile% & echo "%logfile%" >> %logfile%

rem If all went file color the screen green
if "%error%"=="false" color 2f & echo Everything went fine. >> %logfile%
echo on
rem Replace logfile with current version if no errors
if "%error%"=="false" (if exist "%basetarget%\%currentversion%.filesetversion.txt" del "%basetarget%\%currentversion%.filesetversion.txt") & echo File used by Robocopy Controller to determine the fileset version. > "%basetarget%\%filesetversion%.filesetversion.txt"

echo.
echo Press any key to close this screen.
PAUSE > nul

ENDLOCAL