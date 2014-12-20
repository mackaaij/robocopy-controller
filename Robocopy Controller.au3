#Include <File.au3>

;Disable tray menu so script cannot be accidentally paused by clicking tray icon
AutoItSetOption("TrayAutoPause",0)

$windowtitle="Robocopy Controller 2.19"
dim $ErrorTestloop
dim $ErrorInformationTestloop
dim $ErrorRobocopy
dim $ErrorInformationRobocopy
dim $ConfirmInformation
$confirm="true"
$CheckTargetFor="D:\Network Mirror\"

If $CmdLine[0]=0 then
	MsgBox(4096 + 16,$windowtitle,"Usage: Robocopy Controller.exe <fileset> [/noconfirm]")
	Exit
EndIf
$filename=$CmdLine[1]

;Command line setting "/noconfirm" will skip dialog box
If $CmdLine[0]=2 Then
	If $CmdLine[2]="/noconfirm" Then $confirm="false"
EndIf

; Check if file opened for reading OK
$filehandle = FileOpen($filename, 0)
If $filehandle = -1 Then
    MsgBox(16,$windowtitle, "Unable to open/locate fileset: " & $filename)
    Exit
EndIf
FileClose($filehandle)

; Check number of ini sections (should be at least one and is also used to display progess)
$Filesets = IniReadSectionNames($filename)
If @error Then
	MsgBox(16,$windowtitle, "No .ini sections are present in fileset: " & $filename & @LF & @LF & "Are you using the new .ini file structure or still the old .csv?")	
	Exit
EndIf

; Check if Robocopy exist (for now checks for itself and does not check inside PATH only working directory)
If not FileExists("robocopy.exe") Then
    MsgBox(16,$windowtitle, "Robocopy.exe not found. Current working folder: " & @WorkingDir)
	Exit
EndIf

; Set logfile and create it
Dim $Drive, $Dir, $Name, $Ext
_PathSplit($filename,$Drive, $Dir, $Name, $Ext)
$logfile=@TempDir & "\" & $windowtitle & " - " & $Name & $Ext & ".log"
_FileCreate($logfile)
_FileWriteLog($logfile,$windowtitle & " log started")

Func ProcessFile($filename,$state)
	If $state="test" Then
		_FileWriteLog($logfile,"Processing file: " & $filename & " with contents:" & @LF)
		$contents = FileRead($filename)
		_FileWriteLog($logfile,$contents)
		_FileWriteLog($logfile,"--- END CONTENTS ---")
	EndIf
		
	; If supplied state = "test" then the supplied fileset will be tested for errors to these can all be fixed by user
	; If supplied state = "copy" then the supplied fileset will be passed to Robocopy
	$ErrorTestloop = "false"
	$ErrorRobocopy = "false"
	$ErrorInformationTestloop = "ERROR - Cannot continue processing fileset: " & $filename
	$ErrorInformationRobocopy = "WARNING - Robocopy returned errors processing fileset: " & $filename & @LF & "(please check free diskspace and access rights)"
	$ConfirmInformation = "The following mirrors will be executed conform fileset: " & $filename
	
	; For all the .ini sections found in the filename...
	For $sectionnumber = 1 To $Filesets[0] Step 1
		; Read the sourcefolder and check it
		$sourcefolder = IniRead($filename,$Filesets[$sectionnumber],"SourceFolder", "NotFound")
		If $sourcefolder = "NotFound" Or $sourcefolder = "" Then
			$ErrorTestloop="true"
			$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Section " & $Filesets[$sectionnumber] & " supplies no source folder."
		Else
			; Strip trailing backslashes from sourcefolder otherwise Robocopy will fail
			While StringRight($sourcefolder,1)="\"
				$sourcefolder=StringTrimRight ($sourcefolder,1)
			Wend
				
			; Get attributes of sourcefolder (used to check for existance and for verifying it's a folder and not a file) => omschrijven naar
			$attrib = FileGetAttrib($sourcefolder)
			If @error Then 
				$ErrorTestloop="true"
				$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Section " & $Filesets[$sectionnumber] & " supplies a source which cannot be located: " & $sourcefolder
			Else
				If NOT StringInStr($attrib, "D") Then
					$ErrorTestloop="true"
					$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Section " & $Filesets[$sectionnumber] & " supplies a source which is a file and not a folder: " & $sourcefolder
				EndIf
			EndIf
		EndIf
			
		; Read the targetfolder and check it
		$targetfolder = IniRead($filename,$Filesets[$sectionnumber],"TargetFolder", "NotFound")
		If $targetfolder = "NotFound" Or $targetfolder = "" Then
			$ErrorTestloop="true"
			$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Section " & $Filesets[$sectionnumber] & " supplies no target folder."
		Else
			; Strip trailing backslashes from sourcefolder otherwise Robocopy will fail
			While StringRight($targetfolder,1)="\"
				$targetfolder=StringTrimRight ($targetfolder,1)
			Wend
			$ConfirmInformation = $ConfirmInformation & @lf & $Filesets[$sectionnumber] & ": " & $sourcefolder & "->" & $targetfolder
			
			; Check target folder. This should contain either "backup" or start with a text supplied in the beginning of this script
			If StringInStr($targetfolder,"backup",0,1) = 0 Then
				If StringLeft($targetfolder,StringLen($CheckTargetFor))<>$CheckTargetFor Then
					$ErrorTestloop="true"
					$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Section " & $Filesets[$sectionnumber] & " target folder name should contain either 'backup' or start with """ & $CheckTargetFor & """: " & $targetfolder
				EndIf
			EndIf
		EndIf
	
		; Read the other variables (may be left empty so this is the default
		$excludefolders = IniRead($filename,$Filesets[$sectionnumber],"FoldersToExclude", "")
		$excludefiles = IniRead($filename,$Filesets[$sectionnumber],"FilesToExclude", "")
		$filestocopy = IniRead($filename,$Filesets[$sectionnumber],"CopyOnlyTheseFiles", "")
	
		If $state="copy" And $ErrorTestloop="false" Then
			RoboCopy($Filesets[$sectionnumber],$sectionnumber,$Filesets[0],$sourcefolder,$targetfolder,$excludefolders,$excludefiles,$filestocopy)
		EndIf
	Next
EndFunc

Func RoboCopy($UniqueDisplayName,$currentfileset,$totalfilesets,$sourcefolder,$targetfolder,$excludefolders,$excludefiles,$filestocopy)
 	; Build textstring for progress information
	$MainProgressInformation="Processing Robocopy command " & $currentfileset & " of " & $totalfilesets
	$ProgressInformation = "Copying: " & $UniqueDisplayName & @LF & "To: " & $targetfolder
	
	If NOT FileExists($targetfolder) Then $ProgressInformation = $ProgressInformation & @lf & "NOTE: Takes a few minutes on the first run!" & @lf
	_FileWriteLog($logfile,$MainProgressInformation)
	ProgressSet(-1,$ProgressInformation,$MainProgressInformation)
	
	$TrayTipInformation=$ProgressInformation & @lf & "Details:"
	If NOT $excludefolders = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "Folders to exclude: " & $excludefolders
	If NOT $excludefiles = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "File(type)s to exclude: " & $excludefiles
	If NOT $filestocopy = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "File(s) to copy: " & $filestocopy
	If $excludefolders = "" And $excludefiles = "" And $filestocopy = "" Then $TrayTipInformation = $TrayTipInformation & " (none - everything is mirrored)" & $filestocopy
		
	;Log detailed information (variable is still called TrayTip because of historical reasons)
	_FileWriteLog($logfile,$TrayTipInformation)
	;TrayTip disabled since it was an annoyance
	;TrayTip($windowtitle,$TrayTipInformation,-1,17)
	
	;Build parameterlist
	$robocopyparameters=' "' & $sourcefolder & '" "' & $targetfolder & '"'
	If NOT $filestocopy="" Then $robocopyparameters=$robocopyparameters & ' ' & $filestocopy
	If NOT $excludefiles="" Then $robocopyparameters=$robocopyparameters & ' /XF ' & $excludefiles
	If NOT $excludefolders="" Then $robocopyparameters=$robocopyparameters & ' /XD ' & $excludefolders
	$robocopyparameters=$robocopyparameters & ' /S /PURGE /NP /LOG+:"' & $logfile & '" /R:0 /W:0'
	
	_FileWriteLog($logfile,"Executing: robocopy.exe" & $robocopyparameters)
	
	;Execute Robocopy with parameters
	$val = RunWait("robocopy.exe" & $robocopyparameters, "", @SW_HIDE)
	;$val = RunWait(@Comspec & " /C robocopy.exe" & $robocopyparameters, "", @SW_HIDE)
	;$val = RunWait(@ComSpec & " /c " & "robocopy.exe" & $robocopyparameters, @WorkingDir, @SW_HIDE)
	If $val>7 Then
		$ErrorRobocopy="true"
		$ErrorInformationRobocopy = $ErrorInformationRobocopy & @lf & "Line " & $currentfileset & ", errorlevel " & $val & " (" & $sourcefolder & "->" & $targetfolder & ")"
	EndIf
	
	;Set copied files to readonly to stress it's for readonly use
	;Robocopy could also do this with "/A+:R" but only for newly copied files
	FileSetAttrib($targetfolder, "+R", 1)
	
	;Update statistics and clear systemtraytip
	ProgressSet(($currentfileset/$totalfilesets)*100)
	;TrayTip disabled (annoyance) so doesn't have to be reset
	;TrayTip("","",0)
EndFunc

ProcessFile($filename,"test")
If $ErrorTestloop="true" Then
	_FileWriteLog($logfile,$ErrorInformationTestloop)
	MsgBox(4096 + 16,$windowtitle,$ErrorInformationTestloop)
	Exit
EndIf

If $confirm="true" Then
	$continue=MsgBox(4096 + 32 + 1,$windowtitle,$ConfirmInformation)
	If $continue=2 Then
		_FileWriteLog($logfile,"Execution cancelled after display of: " & $ConfirmInformation)
		Exit
	EndIf
EndIf

ProgressOn($windowtitle, "Processing fileset: " & $filename,"",-1,-1,18)
ProcessFile($filename,"copy")

If $ErrorRobocopy="false" Then
	_FileWriteLog($logfile,"Finished without errors.")
	MsgBox(4096 + 64,$windowtitle,"Finished without errors. This box will autoclose in 10 seconds.",10)
Else
	_FileWriteLog($logfile,$ErrorInformationRobocopy)
	MsgBox(4096 + 48,$windowtitle,$ErrorInformationRobocopy)
EndIf