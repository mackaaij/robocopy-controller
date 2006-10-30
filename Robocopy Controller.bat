@echo off
cls
SETLOCAL

set scriptversion=Robocopy Controller 1.2.003
rem Set windowtitle of DOS box
title %scriptversion%

set error=false

rem Check if a fileset is passed as a parameter. If not quit immediatly
if [%1]==[] echo Error: Fileset to be used not specified. & color 4f & echo Press any key to close this screen. & ENDLOCAL & PAUSE > nul & goto :eof

rem Strip the quotes of the parameter
for /f "delims=" %%i in ('echo %1') do set robocopy_fileset=%%~i
rem Check the passed parameter for existance and then use it as the fileset to mirror
rem If the file does not exist quit immediatly
if NOT exist "%robocopy_fileset%" echo Error: Specified fileset does not exist: & echo (%robocopy_fileset%)  & echo Use quotes around the filename? & color 4f & echo Press any key to close this screen. & ENDLOCAL & PAUSE > nul & goto :eof

rem Set name and location for the log file
for /f "delims=" %%i in ('echo %robocopy_fileset%') do set logfile=%temp%\%%~nxi.log.txt

rem Create a new logfile
echo Start %scriptversion% > "%logfile%"

rem Check whether Robocopy exist
if NOT exist robocopy.exe set error=Error: Robocopy.exe missing. & goto :end

rem This sections reads the settings from %robocopy_fileset%
for /F "skip=4 tokens=1,2,3,4,5 delims=;" %%i in ('type "%robocopy_fileset%"') do (set sourcefolder=%%i) & (set destinationfolder=%%j) & (set excludefolders=%%k) & (set excludefiles=%%l) & (set filestocopy=%%m) & call :testfileset

rem If error has been set the fileset is not correct. Then quit, else goto next step
if NOT "%error%"=="false" goto :end
pause & goto :readfileset

:testfileset
rem Check the fileset for existance of all variables
set testempty="%excludefolders%"
if %testempty% == "" set error=Error: Fileset contains non-empty tokens (use a space). & goto :eof
set testempty="%excludefiles%"
if %testempty% == "" set error=Error: Fileset contains non-empty tokens (use a space). & goto :eof
set testempty="%filestocopy%"
if %testempty% == "" set error=Error: Fileset contains non-empty tokens (use a space). & goto :eof

rem Exit the loop :testfileset
goto :eof

:readfileset
rem The subroutine :robocopy is called for each line
for /F "skip=4 tokens=1,2,3,4,5 delims=;" %%i in ('type "%robocopy_fileset%"') do (set sourcefolder=%%i) & (set destinationfolder=%%j) & (set excludefolders=%%k) & (set excludefiles=%%l) & (set filestocopy=%%m) & call :robocopy

rem If this line in the script is reached the complete %robocopy_fileset% is done
goto :end

:robocopy
rem Strip the trailing space from the variables if there is one (symbol for empty token)
if "%excludefolders:~-1%" == " " set excludefolders=%excludefolders:~0,-1%
if "%excludefiles:~-1%" == " " set excludefiles=%excludefiles:~0,-1%
if "%filestocopy:~-1%" == " " set filestocopy=%filestocopy:~0,-1%

rem Strip trailing backslash from source and destination directories if there is one.
rem Otherwise Robocopy will fail...
if "%sourcefolder:~-1%" == "\" set sourcefolder="%sourcefolder:~0,-1%"
if "%destinationfolder:~-1%" == "\" set destinationfolder="%destinationfolder:~0,-1%"

rem Check whether the sourcefolder exists
if NOT exist "%sourcefolder%" set error=Error: Source (%sourcefolder%) does not exist. & goto :eof

rem Output read options to screen
echo Robocopy is busy mirroring (source -^> destination)...
if NOT exist "%destinationfolder%" echo PLEASE NOTE: This may take a few minutes on the first run!
echo * %sourcefolder% -^> %destinationfolder%
if NOT "%excludefolders%" == "" echo - Folders to exclude: %excludefolders%
if NOT "%excludefiles%" == "" echo - File(type)s to exclude: %excludefiles%
if NOT "%filestocopy%" == "" echo - File(s) to copy: %filestocopy%

rem Output read options to log
echo Robocopy is busy mirroring (source -^> destination)... >> "%logfile%"
echo * %sourcefolder% -^> %destinationfolder% >> "%logfile%"
if NOT "%excludefolders%" == "" echo - Folders to exclude: %excludefolders% >> "%logfile%"
if NOT "%excludefiles%" == "" echo - File(type)s to exclude: %excludefiles% >> "%logfile%"
if NOT "%filestocopy%" == "" echo - File(s) to copy: %filestocopy% >> "%logfile%"

rem Build parameters
rem /XD are folders to exclude
if NOT "%excludefolders%"=="" set excludefolders=/XD %excludefolders%
rem /XF are file(type)s to exclude
if NOT "%excludefiles%"=="" set excludefiles=/XF %excludefiles%

rem Extra parameters explained
rem /S /PURGE
rem MIRror a directory tree but do NOT include empty subfolders
rem /MIR would include empty subfolders and is equivalent to /E /PURGE
rem Unfortunatly Robocopy will not delete folders which have later been configured to ignore,
rem unless they've been removed from the network.
rem /ZB
rem Use restartable mode (survive network glitch); if access denied use Backup mode.
rem /NP
rem No progress (since output is logged to a logfile)
rem /LOG+
rem Append logfile (if multiple folders are mirrored every log is contained)
rem /R:0 /W:0
rem Retry 0 times with a 0 second pause between each try if copy fails (insufficient disk space)
rem Default was 1.000.000 retries with 30 seconds pause for EACH file.
robocopy "%sourcefolder%" "%destinationfolder%" %filestocopy% %excludefiles% /S /PURGE /ZB /NP /LOG+:"%logfile%" /R:0 /W:0 %excludefolders%
if %errorlevel%==16 set error=Error: Roboform exit code 16 (wrong "%robocopy_fileset%" or network access)? & goto :eof
if %errorlevel%==9 set error=Error: Roboform exit code 9 (not enough diskspace on drive %destinationfolder:~0,1%)? & goto :eof
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
echo. >> "%logfile%"
echo Finished Robocopy script. >> "%logfile%"
if NOT "%error%"=="false" color 4f & echo.  >> "%logfile%" & echo Unfortunatly something(s) went wrong.  > "%logfile%" & echo %error%  >> "%logfile%" & echo.  >> "%logfile%" & echo If this screen output is not sufficient please check the logfile at:  >> "%logfile%" & echo "%logfile%" >> "%logfile%"

rem If all went file color the screen green
if "%error%"=="false" echo Everything went fine. >> "%logfile%"

echo.
echo Press any key to close this screen.
PAUSE > nul

ENDLOCAL