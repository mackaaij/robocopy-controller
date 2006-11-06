@echo on
cls
REM Script to remove obsolete folders in the Network Mirror.
REM As Robocopy keeps copied files that still exist on the network.

ECHO Cleaning up Network Mirror, please wait...

REM [YYYY-MM-DD] What's deleted and why
set foldertodelete="D:\Network Mirror\FOLDER NAME"
if exist %foldertodelete% rmdir /s/q %foldertodelete%

REM Free variable and quit
set foldertodelete=

exit