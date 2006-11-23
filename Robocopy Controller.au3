#Include <File.au3>

$windowtitle="Robocopy Controller 2.0.004"
$tokensrequired=5
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

;At first another target folder was used.
If FileExists("D:\Network Offline") Then DirMove("D:\Network Offline","D:\Network Mirror")

; Check if file opened for reading OK
$filehandle = FileOpen($filename, 0)
If $filehandle = -1 Then
    MsgBox(16,$windowtitle, "Unable to open/locate fileset: " & $filename)
    Exit
EndIf
; Check number of lines (should be at least one and is also used to display progess)
$numberoflines=_FileCountLines($filename)
FileClose($filehandle)
If $numberoflines = 0 Then
	MsgBox(16,$windowtitle, "No lines present in fileset: " & $filename)	
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
$logfile=@TempDir & "\" & $Name & $Ext & ".log"
_FileCreate($logfile)
_FileWriteLog($logfile,$windowtitle & " log started")

Func ProcessFile($filename,$state)
	$filehandle = FileOpen($filename, 0)
	
	If $state="test" Then _FileWriteLog($logfile,"Processing file: " & $filename)
	
	; If supplied state = "test" then the supplied fileset will be tested for errors to these can all be fixed by user
	; If supplied state = "copy" then the supplied fileset will be passed to Robocopy
	$ErrorTestloop = "false"
	$ErrorRobocopy = "false"
	$ErrorInformationTestloop = "ERROR - Cannot continue processing fileset: " & $filename
	$ErrorInformationRobocopy = "WARNING - Robocopy returned errors processing fileset: " & $filename & @LF & "(please check free diskspace and access rights)"
	$ConfirmInformation = "The following mirrors will be executed conform fileset: " & $filename
	$linenumber=0
	
	; Read in lines of text until the EOF is reached
	While 1
		$linenumber=$linenumber+1
		$line = FileReadLine($filehandle)
		If @error = -1 Then ExitLoop
		
		;Output read lines to log in the first run
		If $state="test" Then _FileWriteLog($logfile,"Line " & $linenumber & ": " & $line)
		
		$tokens = StringSplit($line, ";")
		; Check if the number of tokens equals the required number of tokens
		if $tokens[0]<>$tokensrequired then
			$ErrorTestloop="true"
			$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Line " & $linenumber & " supplies " & $tokens[0] & " tokens instead of " & $tokensrequired & "."
		EndIf
	
		; Make the tokens readable to human, format and check them
		If $tokens[0]>0 Then
			$sourcefolder=$tokens[1]
			; Strip trailing backslashes from sourcefolder otherwise Robocopy will fail
			While StringRight($sourcefolder,1)="\"
				$sourcefolder=StringTrimRight ($sourcefolder,1)
			Wend
			
			; Get attributes of sourcefolder (used to check for existance and for verifying it's a folder and not a file)
			$attrib = FileGetAttrib($sourcefolder)
			If @error Then 
				$ErrorTestloop="true"
				$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Line " & $linenumber & " supplies a source which cannot be located: " & $sourcefolder
			Else
				If NOT StringInStr($attrib, "D") Then
					$ErrorTestloop="true"
					$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Line " & $linenumber & " supplies a source which is a file and not a folder: " & $sourcefolder
				EndIf
			EndIf
		EndIf
		
		If $tokens[0]>1 Then
			$destinationfolder=$tokens[2]
			; Strip trailing backslashes from sourcefolder otherwise Robocopy will fail
			While StringRight($destinationfolder,1)="\"
				$destinationfolder=StringTrimRight ($destinationfolder,1)
			Wend
			$ConfirmInformation = $ConfirmInformation & @lf & $sourcefolder & "->" & $destinationfolder
			If StringLeft($destinationfolder,StringLen($CheckTargetFor))<>$CheckTargetFor Then
				$ErrorTestloop="true"
				$ErrorInformationTestloop = $ErrorInformationTestloop & @lf & "Line " & $linenumber & " destination folder should start with """ & $CheckTargetFor & """: " & $destinationfolder
			EndIf
		EndIf
		
		if $tokens[0]>2 Then $excludefolders=$tokens[3]
		if $tokens[0]>3 Then $excludefiles=$tokens[4]
		if $tokens[0]>4 Then $filestocopy=$tokens[5]
	
		If $state="copy" And $ErrorTestloop="false" Then
			RoboCopy($linenumber,$numberoflines,$sourcefolder,$destinationfolder,$excludefolders,$excludefiles,$filestocopy)
		EndIf
	Wend
	FileClose($filehandle)
EndFunc

Func RoboCopy($currentfileset,$totalfilesets,$sourcefolder,$destinationfolder,$excludefolders,$excludefiles,$filestocopy)
 	; Build textstring for progress information
	$MainProgressInformation="Processing fileset " & $currentfileset & " of " & $totalfilesets
	$ProgressInformation = $sourcefolder & " ->" & @LF & $destinationfolder
	
	If NOT FileExists($destinationfolder) Then $ProgressInformation = $ProgressInformation & @lf & "NOTE: Takes a few minutes on the first run!" & @lf
	_FileWriteLog($logfile,$MainProgressInformation)
	ProgressSet(-1,$ProgressInformation,$MainProgressInformation)
	
	$TrayTipInformation=$ProgressInformation & @lf & "Details:"
	If NOT $excludefolders = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "Folders to exclude: " & $excludefolders
	If NOT $excludefiles = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "File(type)s to exclude: " & $excludefiles
	If NOT $filestocopy = ""  Then $TrayTipInformation = $TrayTipInformation & @lf & "File(s) to copy: " & $filestocopy
	If $excludefolders = "" And $excludefiles = "" And $filestocopy = "" Then $TrayTipInformation = $TrayTipInformation & " (none - everything is mirrored)" & $filestocopy
		
	;Display and log detailed information in system tray (if user has not disabled balloontips)
	_FileWriteLog($logfile,$TrayTipInformation)
	TrayTip($windowtitle,$TrayTipInformation,-1,17)
	
	;Build parameterlist
	$robocopyparameters=' "' & $sourcefolder & '" "' & $destinationfolder & '"'
	If NOT $filestocopy="" Then $robocopyparameters=$robocopyparameters & ' ' & $filestocopy
	If NOT $excludefiles="" Then $robocopyparameters=$robocopyparameters & ' /XF ' & $excludefiles
	If NOT $excludefolders="" Then $robocopyparameters=$robocopyparameters & ' /XD ' & $excludefolders
	$robocopyparameters=$robocopyparameters & ' /S /PURGE /ZB /NP /LOG+:"' & $logfile & '" /R:0 /W:0'
	
	_FileWriteLog($logfile,"Executing: robocopy.exe" & $robocopyparameters)
	
	;Execute Robocopy with parameters
	$val = RunWait("robocopy.exe" & $robocopyparameters, "", @SW_HIDE)
	If $val>7 Then
		$ErrorRobocopy="true"
		$ErrorInformationRobocopy = $ErrorInformationRobocopy & @lf & "Line " & $currentfileset & ", errorlevel " & $val & " (" & $sourcefolder & "->" & $destinationfolder & ")"
	EndIf
	
	;Set copied files to readonly to stress it's for readonly use
	;Robocopy could also do this with "/A+:R" but only for newly copied files
	FileSetAttrib($destinationfolder, "+R", 1)
	
	;Update statistics and clear systemtraytip
	ProgressSet(($currentfileset/$totalfilesets)*100)
	TrayTip("","",0)
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
