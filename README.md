# Robocopy Controller

[AutoIt](https://www.autoitscript.com/site/) script for mobile workers to bring along files from the network for offline usage. Concerns a mirror from the network, so no sync back.

## How it works in general
Microsoft's Robocopy (Robust File Copy) does the hard work. This script reads parameters from an .ini file, applies some hard coded ones and displays progress for end users.

In the .ini one can configure sub folders to ignore and either files to ignore or files to copy.

The target folder needs to be either "D:\Network Mirror\"  or contain the characters 'backup' to prevent you from mirroring over an existing directory.

If you mirrored a sub folder and change your mind, Robocopy will not remove it locally as it still exists on the network. For this, you can either rename the network folder, start over or maintain and run "Network Mirror cleanup.bat" locally.

## Setup Robocopy Controller
Robocopy Controller.exe should be started with at least one parameter, pointing towards the .ini file containing the configuration.

A Windows Shortcut could be something like:
"\\server\share\applicaties\Robocopy controller\Robocopy Controller.exe" "\\server\share\applicaties\Robocopy Controller\robocopy fileset.ini"

You can add the parameter `/noconfirm` to start the process immediately. By default there is a slight delay to allow end users to cancel the process when in a hurry.

## Robocopy Controller daily usage
Robocopy Controller checks whether the end user can access the folders to be mirrored.

Robocopy Controller shows a progress bar to the end user. It increases per block in the .ini file (so not the amount of files or bytes to be mirrored).

A log file is kept in %temp% map. Robocopy will be started with parameters `/S /PURGE /ZB /NP /R:0 /W:0 /LOG+:<name of the logfile determined from .ini filename>`. If something went wrong, you'll see an error showing Robocopy's error level.

After mirroring, files are flagged as read only to prevent end users from making changes by mistake. Robocopy's parameter `/A+:R` isn't sufficient here at it would only apply to newly copied files.