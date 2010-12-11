-----------------------------------------------------------------------------------------------------------------
--SkimFlip is an accelerometer-driven document rotation AppleScript applet that works with the free PDF reader Skim. Skim is available at http://skim-app.sourceforge.net/index.html

--This script was written by Eric Nitardy ((c)2010). It is available from The Modbookish and may be modified and redistributed provided appropriate credits are given, and they accompany the script.

--This script uses the Unix utility smsutil written by Daniel Griscom ((c)2007-2010). Please read the accompanying "smsutilCREDITS" and "smsutilLICENSE" file for more information or visit his web site at http://www.suitable.com

-----------------------------------------------------------------------------------------------------------------


global smsutilPath, orientCheckDelay, sinIgnore, sinHiTilt, sinFlip, cosFlip, systemInfo, notebookOrient, notebookTilt, documentOrient, pauseMacFlip, tiltCount, lastPage, lastPageCount, lastPages, lastPagesAll, wasFacing, iconPath, iconPathDim, manTurnPages


property typeComputer : "unknown" -- Is the computer a "MacBook" or "Modbook"?

property displayWidth : 32.5 -- Display width in centimeters. --- Make Square For SkimFlip
property displayHeight : 32.5 -- Display height in centimeters.

property cosMacAdjust : 0.5 -- cosine of apx. angle of a MacBook screen tilt (60 degrees).
property sinMacAdjust : 0.8660254 -- sine of apx. angle of a MacBook screen tilt (60 degrees).

property orientCheckDelayP : 0.55 -- Number of seconds between each time the script updates the computer's orientation.

property extraFunctions : false --  Availablity of extra functionality.  --May 22

--------------------------------------------------------------------
------- "on run" initializes the main global variables -------
--------------------------------------------------------------------
on run
	
	set orientCheckDelay to orientCheckDelayP -- Number of seconds between each time the script updates the computer's orientation.
	
	set displayDiagonal to (displayWidth ^ 2 + displayHeight ^ 2) ^ 0.5
	set sinIgnore to 0.27 -- sine of angle off flat before script considers rotating the display (~15 degrees).
	set sinHiTilt to 0.42 -- sine of angle of tilt for fast page turning (~30 degrees).
	set tiltCount to 0
	
	----------- Calculate sine and cosine of Flip Angle -----------
	set sinFlip to displayHeight / displayDiagonal
	set cosFlip to displayWidth / displayDiagonal
	
	------ Paths to various files in /Contents/Resources/ ------
	set smsutilPath to quoted form of (POSIX path of (path to resource "smsutil"))
	set iconPath to path to resource "applet.icns"
	set iconPathDim to path to resource "SkimFlipDim.icns"
	
	set documentOrient to getDocOrient() -- Orientation of document
	if documentOrient is -1 then
		set notebookOrient to 0
	else
		set notebookOrient to documentOrient -- Orientation of notebook
	end if
	set notebookTilt to 0 -- Page turning tilt: -2, -1, 0, 1, 2
	set lastPageCount to 0 -- # of Cycles on same page
	set lastPage to getPage() -- {document name, current page}
	set lastPages to {lastPage, lastPage} -- last two reading locations of current document
	set lastPagesAll to {} -- lastPages of other documents
	set pauseMacFlip to false -- flag indicates whether SkimFlip is paused
	set manTurnPages to false -- Flag indicating manual page turning mode
	set wasFacing to {false, false} -- indicates previous facing state {non-continuous, continuous}
	
	
	-------- Determine Model ID and Graphics Chip for System --------
	set systemInfo to systemsInfo()
	
	-- Determine notebook type (MacBook or Modbook) --
	------ and decide on MacFlip's rotation behavior -------
	--display alert "'" & (item 3 of systemInfo) & "'   '" & typeComputer & "'"
	if typeComputer is "unknown" then
		if (item 3 of systemInfo) is "Color LCD" then
			set typeComputer to "macbook"
		else
			set typeComputer to "modbook"
		end if
	end if
	if typeComputer is "macbook" or typeComputer is "macbook as modbook" then
		tell application "Skim"
			activate
			display alert "Your notebook appears to be a MacBook, not a Modbook." message "You have options for how SkimFlip will function:" & return & "    ** Modbook functionality - Rotate the document based on the orientation of the notebook's base." & return & "    ** MacBook functionality - Rotate the document based on the orientation of the notebook's screen," & return & "       which is assumed to be tilted up at an angle of 60 degrees." buttons {"This is a Modbook!", "MacBook functionality", "Modbook functionality"} default button 3 giving up after 100
			
			if button returned of result is "MacBook functionality" then
				set typeComputer to "macbook"
			else if button returned of result is "This is a Modbook!" then
				set typeComputer to "modbook"
			else
				set typeComputer to "macbook as modbook"
			end if
			
		end tell
	end if
	
	
	(*
	------ Provide escape sequences for spaces in path of smsutil ------
	set TID to text item delimiters
	set text item delimiters to " "
	set aList to every text item of (smsutilPath as text)
	set text item delimiters to "\\ "
	set smsutilPath to aList as text
	set text item delimiters to TID
	*)
	
	
	tell application "System Events"
		set frontmost of process "Skim" to true
	end tell
	return
	
end run
---------------------------------------------------------------------------
---------------------------------------------------------------------------




---------------------------------------------------------------------------
------- "on idle" repeats every orientCheckDelay seconds -------
---------------------------------------------------------------------------
on idle
	
	------- If Skim document not ready, suspend app  -------
	tell application "System Events"
		get name of (process 1 where it is frontmost)
	end tell
	if result is not "Skim" then
		return 7 * orientCheckDelayP
	end if
	try
		tell application "Skim"
			if (exists document 1) is not true then
				return 4 * orientCheckDelayP
			end if
		end tell
	on error
		return 4 * orientCheckDelayP
	end try
	
	
	set {notebookOrient, notebookTilt} to getNotebookOrient("4")
	
	--------------------------------- Errors ---------------------------------
	---------------------------------------------------------------------------	
	if notebookOrient is -1 then
		tell application "Skim"
			activate
			display alert "SMS Utility:  smsutil  is missing" & return message "The smsutil utility is suppose to be inside the SkimFlip application bundle (in /Contents/Resources). Someone (probably the AppleScript Editor) may have removed it."
			
		end tell
		quit
		return 0.5
		
	else if notebookOrient is -2 then
		tell application "Skim"
			activate
			display alert "SMS Utility: SMS  is not functioning properly." & return message "Your sudden motion sensor may not be working."
			
		end tell
		quit
		return 0.5
		
		
		------------------ Error -3 is notebook upside down ----------------
		---------------------------------------------------------------------------			
	else if notebookOrient is -3 then
		
		try
			do shell script "afplay '/System/Library/Sounds/Tink.aiff'"
		on error
			beep 1
		end try
		delay 0.5
		tell application "Skim"
			activate
			display dialog "Return to Last Reading Location." buttons {"OK"} default button 1 giving up after 1 with icon iconPath
		end tell
		--set {notebookOrient, notebookTilt} to {getDocOrient(), 0}
		set {notebookOrient, notebookTilt} to getNotebookOrient("3")
		if notebookOrient >= 0 then
			set nowPage to getPage()
			if (item 1 of nowPage) is not (item 1 of item 2 of lastPages) then
				set lastPages to getRightDoc(nowPage, lastPages)
			end if
			if item 2 of lastPages is nowPage then
				
				if (item 2 of item 1 of lastPages) is not -1 then setPage(item 2 of item 1 of lastPages)
			else
				if (item 2 of item 2 of lastPages) is not -1 then setPage(item 2 of item 2 of lastPages)
			end if
			return orientCheckDelay
		end if
		if pauseMacFlip is false then
			try
				do shell script "afplay '/System/Library/Sounds/Submarine.aiff'"
			on error
				beep 2
			end try
			
			if manTurnPages is false then
				set thePrompt to "SkimFlip is Paused,"
				set secButton to "Turn Pages with Stylus"
				set theAltButton to "Send Escape Key"
			else
				set thePrompt to "SkimFlip is Paused,"
				set secButton to "Turn Pages by Tilting"
				set theAltButton to "Send Escape Key"
			end if
			tell application "Skim"
				activate
				display dialog (thePrompt & return & "but other options also available.") buttons {theAltButton, secButton, "Pause SkimFlip"} default button 3 giving up after 7 with icon iconPathDim
			end tell
			if button returned of result is "" then
				set pauseMacFlip to true
				set manTurnPages to false
				set orientCheckDelay to 3 * orientCheckDelayP
				return orientCheckDelay
				
			else if button returned of result is "Send Escape Key" then
				tell application "System Events"
					key code 53
					quit
				end tell
			else if button returned of result is "Turn Pages with Stylus" then
				do shell script "afplay '/System/Library/Sounds/Frog.aiff'"
				set manTurnPages to true
			else if button returned of result is "Pause SkimFlip" then
				delay 1.0
				set pauseMacFlip to true
				set orientCheckDelay to 3 * orientCheckDelayP
				return orientCheckDelay
			else if button returned of result is "Turn Pages by Tilting" then
				do shell script "afplay '/System/Library/Sounds/Purr.aiff'"
				set pauseMacFlip to false
				set manTurnPages to false
				set orientCheckDelay to orientCheckDelayP
				return orientCheckDelay
			end if
			
		else
			try
				do shell script "afplay '/System/Library/Sounds/Blow.aiff'"
			on error
				beep
			end try
			tell application "Skim"
				activate
				display dialog ("SkimFlip is Reactivated.") buttons {"OK"} giving up after 2 with icon iconPath
				
			end tell
			
			delay 0.6
			
			set pauseMacFlip to false
			set orientCheckDelay to orientCheckDelayP
			return orientCheckDelay
			
		end if
		
		set orientCheckDelay to orientCheckDelayP
		return orientCheckDelay * 2
		
		
	else ---------- No  Errors ----------
		----------------------------------
		
		---- Determine # cycles remaining on page ----
		------ If 6 cycles, save as reading location ------
		set nowPage to getPage()
		if lastPage is nowPage then
			if lastPageCount is 6 then
				if item 2 of lastPages is not nowPage then
					set lastPages to {item 2 of lastPages, nowPage}
					--display alert ((item 1 of lastPages) as string) & ":" & ((item 2 of lastPages) as string)
				end if
			end if
			set lastPageCount to lastPageCount + 1
		else
			if (item 1 of nowPage) is not (item 1 of lastPage) then
				set lastPages to getRightDoc(nowPage, lastPages)
			end if
			
			set lastPageCount to 0
		end if
		set lastPage to nowPage
		
		------------- If SkimFlip is paused, skip to end of handler -------------
		if pauseMacFlip is false then
			
			
			
			-------- Log present Document and notebook orientation --------	
			set documentOrient to getDocOrient()
			log {documentOrient, notebookOrient}
			
			if documentOrient is -1 then
				try
					tell application "Skim"
						get document 1
						set notebookOrientS to "documentOrientation:  " & (documentOrient as string) & return
						set notebookOrientS to "notebookOrientation:  " & (notebookOrient as string) & return
						
						activate
						display alert "SkimFlip:  Skim's document unresponsive at the moment." & return message (notebookOrientS & notebookOrientS) giving up after 5
						
					end tell
				end try
				
				--- If different, set document orientation to notebook orientation ---
				---------------------------------------------------------------------------------
			else if documentOrient is not notebookOrient then
				set documentOrient to ChangeDocOrient(notebookOrient)
				
				if documentOrient is less than 0 then
					try
						tell application "Skim"
							get document 1
							set notebookOrientS to "documentOrientation:  " & (documentOrient as string) & return
							set notebookOrientS to "notebookOrientation:  " & (notebookOrient as string) & return
							
							activate
							display alert "SkimFlip:  Skim's page rotation is not working at the moment." & return message (notebookOrientS & notebookOrientS) giving up after 5
							
						end tell
					end try
					
				end if
				
				set tiltCount to 0
				set orientCheckDelay to orientCheckDelayP
				
				-- Do something harmless to keep OS from going to Sleep --
				tell application "System Events" to key code 114 using shift down
			else if notebookTilt is 0 then
				set tiltCount to 0
				set orientCheckDelay to orientCheckDelayP
				
			else
				
				----------- Page turning speed regulator -----------
				----------------------------------------------------------				
				if tiltCount = 0 then
					set orientCheckDelay to 1.2 * orientCheckDelayP
					
				else
					if manTurnPages is true then
						--------- Manual Page Turning ---------
						---------------------------------------------
						if extraFunctions is true then
							if notebookTilt = 2 then
								
								tell application "System Events" to keystroke "z" using {command down, shift down}
							else if notebookTilt = -2 then
								-- If tilt left, Undo, one per cycle --
								tell application "System Events" to keystroke "z" using {command down}
								
							end if
						end if
					else
						----------- Tilt to Turn Page -----------
						-------------------------------------------
						if notebookTilt = 1 or notebookTilt = -1 then -- slow turning
							if tiltCount = 1 then
								--set lastPages to {item 2 of lastPages, getPage()}
								set orientCheckDelay to 0.9 * orientCheckDelayP
								turnPage(notebookTilt)
								-- Do something harmless to keep OS from going to Sleep
								tell application "System Events" to key code 114 using shift down
							else if tiltCount <= 12 then
								set orientCheckDelay to 0.1 * orientCheckDelayP
								turnPage(notebookTilt)
								delay orientCheckDelayP * (1.4 - 0.11 * (tiltCount))
							else
								set orientCheckDelay to 0.15 * orientCheckDelayP
								turnPage(notebookTilt)
							end if
							
						else -- fast turning
							if tiltCount = 1 then
								--set lastPages to {item 2 of lastPages, getPage()}
								set orientCheckDelay to 0.9 * orientCheckDelayP
								turnPage(notebookTilt / 2)
								-- Do something harmless to keep OS from going to Sleep
								tell application "System Events" to key code 114 using shift down
							else if tiltCount <= 6 then
								set orientCheckDelay to 0.15 * orientCheckDelayP
								turnPage(notebookTilt / 2)
								delay orientCheckDelayP * (1.2 - 0.2 * (tiltCount))
							else if tiltCount <= 12 then
								set orientCheckDelay to 0.1 * orientCheckDelayP
								turnPage(notebookTilt / 2)
							else
								set saveTilt to {notebookOrient, notebookTilt}
								set nowTilt to saveTilt
								repeat while saveTilt is nowTilt
									turnPage(notebookTilt)
									delay 0.025
									set nowTilt to getNotebookOrient("2")
								end repeat
							end if
						end if
					end if
				end if
				set tiltCount to tiltCount + 1
				
			end if
			
		end if
		
		--- Pause for a bit before repeating ---
		return orientCheckDelay
	end if
end idle
---------------------------------------------------------------------------
---------------------------------------------------------------------------

----- on quit restore wasFacing if necessary quit System Events

---------------------------------------------------------------------------
----------- Determine the orientation of the notebook -----------
---------------------------------------------------------------------------
on getNotebookOrient(sampSize)
	
	--------------- Get force vectors from the SMS ---------------
	try
		set theOutput to do shell script (smsutilPath & " -i0.025  -c" & sampSize)
	on error
		return {-1, 0}
	end try
	
	---------- Convert the force vector text to a list -----------
	set TID to text item delimiters
	set text item delimiters to return
	set vectorList to every text item of (theOutput as text)
	set text item delimiters to space
	repeat with i from 1 to count of vectorList
		set item i of vectorList to every text item of item i of vectorList
	end repeat
	set text item delimiters to TID
	
	
	----------------------- Find vector magnitudes ------------------------
	------ If vectorList not numbers, then SMS not functioning ------
	try
		set vectorMags to {}
		repeat with i from 1 to count of vectorList
			set item 1 of item i of vectorList to (item 1 of item i of vectorList) as real
			set xCoord to item 1 of item i of vectorList
			set item 2 of item i of vectorList to (item 2 of item i of vectorList) as real
			set yCoord to item 2 of item i of vectorList
			set item 3 of item i of vectorList to (item 3 of item i of vectorList) as real
			set zCoord to item 3 of item i of vectorList
			set the end of vectorMags to (xCoord ^ 2 + yCoord ^ 2 + zCoord ^ 2) ^ 0.5
		end repeat
	on error
		return {-2, 0}
	end try
	
	--------------- Find an average vector --------------
	-------- ignoring shock-type force vectors ---------
	set avVector to {0, 0, 0}
	set m to 0
	repeat with i from 1 to count of vectorList
		if (item i of vectorMags) is greater than 0.7 and (item i of vectorMags) is less than 1.3 then
			repeat with j from 1 to 3
				set item j of avVector to (item j of avVector) + (item j of item i of vectorList) / (item i of vectorMags)
				
			end repeat
			set m to m + 1
		end if
	end repeat
	
	if m is not 0 then
		repeat with j from 1 to 3
			set item j of avVector to (item j of avVector) / m
		end repeat
		
		------- Set x,y,z coordinates ---------
		----- adjusting for odd SMS's  ------
		set xCoord to (item 1 of avVector)
		set yCoord to item 2 of avVector
		set zCoord to (item 3 of avVector)
		
		
		------- For a MacBook, set the rotation around the screen--------
		------- which is assumed to be at a set angle to the base --------
		ignoring case
			if typeComputer is "Macbook" then
				set yCoord to cosMacAdjust * yCoord + sinMacAdjust * zCoord
				set zCoord to -sinMacAdjust * yCoord + cosMacAdjust * zCoord
			end if
		end ignoring
		
		
		-------------- Calculate notebook orientation --------------
		set longMag to (xCoord ^ 2 + yCoord ^ 2) ^ 0.5
		set notebookTilt to 0
		if longMag is greater than sinIgnore then
			
			-------- These are "Skim" orientations: 
			-- 90 & 270 are reversed from display orientations --
			if yCoord / longMag is greater than sinFlip then
				set notebookOrient to 0
				set notebookTilt to getTilt(xCoord / longMag)
			else
				if yCoord / longMag is less than -sinFlip then
					set notebookOrient to 180
					set notebookTilt to getTilt(-xCoord / longMag)
				else
					if xCoord / longMag is greater than cosFlip then
						set notebookOrient to 90
						set notebookTilt to getTilt(-yCoord / longMag)
					else
						if xCoord / longMag is less than -cosFlip then
							set notebookOrient to 270
							set notebookTilt to getTilt(yCoord / longMag)
						end if
					end if
				end if
			end if
			
		else
			if zCoord is less than 0 then
				return {-3, 0}
			end if
			--set notebookTilt to 0
			if notebookOrient < 0 then
				set notebookOrient to getDocOrient()
				if notebookOrient < 0 then set notebookOrient to 0
			end if
		end if
	end if
	return {notebookOrient, notebookTilt}
	
end getNotebookOrient


---------------------------------------------------------------------------
--------------- Determine the tilt of the notebook ----------------
---------------------------------------------------------------------------
on getTilt(theSine)
	if theSine <= -sinHiTilt then
		return 2
	else
		if theSine <= -sinIgnore then
			return 1
		else
			if theSine >= sinHiTilt then
				return -2
			else
				if theSine >= sinIgnore then
					return -1
				else
					return 0
				end if
			end if
		end if
	end if
end getTilt



---------------------------------------------------------------------------
---- Get System information: Model ID and Graphic chip set ----
---------------------------------------------------------------------------
on systemsInfo()
	set TID to text item delimiters
	set text item delimiters to ": "
	set theModel to do shell script "/usr/sbin/system_profiler SPHardwareDataType |  grep " & quoted form of "Model Identifier:"
	set theModel to text item 2 of theModel
	set theGraphics to do shell script "/usr/sbin/system_profiler SPDisplaysDataType | grep " & quoted form of "Chipset Model:"
	set theGraphics to text item 2 of theGraphics
	set theDisplay to do shell script "/usr/sbin/system_profiler SPDisplaysDataType"
	set text item delimiters to ":" & return & "          Resolution:"
	set theDisplay to text item 1 of theDisplay
	set text item delimiters to return & "        "
	set theDisplay to text item -1 of theDisplay
	set text item delimiters to TID
	
	return {theModel, theGraphics, theDisplay}
end systemsInfo

------------------------------------------------------------
------- Determine document page orientation ------
-------- return a -1 if there is an error ---------------
------------------------------------------------------------
on getDocOrient()
	try
		tell application "Skim"
			--get current page of document 1
			set DocOrient to rotation of current page of document 1
			
		end tell
		
		return DocOrient
	on error
		return -1
	end try
end getDocOrient



------------------------------------------------------------
------ Change the document page orientation ------
-------- return a -1 if there is an error ---------------
------------------------------------------------------------
on ChangeDocOrient(notebookOrient)
	try
		tell application "Skim"
			tell document 1
				get view settings
				set isFacing to {(display mode of result) is two up, (display mode of result) is two up continuous}
				--- For large documents, rotate nearby pages first ---
				try
					set rotation of pages ((index of current page) - 1) thru ((index of current page) + 1) to notebookOrient
				on error
					set rotation of pages ((index of current page) - 1) thru ((index of current page) + 0) to notebookOrient
				end try
				
				if item 1 of isFacing is true then
					if notebookOrient / 180 as integer is notebookOrient / 180 then
						set wasFacing to {false, false}
					else
						set view settings to {display mode:single page}
						set wasFacing to {true, false}
					end if
				else if item 2 of isFacing is true then
					if notebookOrient / 180 as integer is notebookOrient / 180 then
						set wasFacing to {false, false}
					else
						set view settings to {display mode:single page continuous}
						set wasFacing to {false, true}
					end if
					
				else if item 1 of wasFacing is true then
					if notebookOrient / 180 as integer is notebookOrient / 180 then
						set view settings to {display mode:two up}
						set wasFacing to {false, false}
					end if
				else if item 2 of wasFacing is true then
					if notebookOrient / 180 as integer is notebookOrient / 180 then
						set view settings to {display mode:two up continuous}
						set wasFacing to {false, false}
					end if
				end if
				set rotation of every page to notebookOrient
			end tell
		end tell
		
		return notebookOrient
	on error
		return -1
	end try
end ChangeDocOrient



----------- Turn Document Page -----------
-------------------------------------------------
on turnPage(notebookTilt)
	try
		tell application "Skim"
			tell document 1
				set numPage to (index of current page)
				if numPage + notebookTilt >= 0 then
					set current page to (page (numPage + notebookTilt))
				end if
			end tell
		end tell
		
		return 0
	on error
		return -1
	end try
end turnPage

----------- Get Document Page -----------
-----------------------------------------------
on getPage()
	try
		tell application "Skim"
			set thePage to index of current page of document 1
			set theDoc to name of document 1
		end tell
		return {theDoc, thePage}
	on error
		return {"", 0}
	end try
end getPage



on getRightDoc(nowPage, lastPages)
	set the end of lastPagesAll to lastPages
	set docFound to false
	set lengthList to number of items in lastPagesAll
	set emptyList to {}
	repeat with i from 1 to lengthList
		
		if (item 1 of item 2 of item i of lastPagesAll) is (item 1 of nowPage) then
			set docFound to true
			set lastPages to item i of lastPagesAll
		else
			set end of emptyList to item i of lastPagesAll
		end if
		
	end repeat
	if docFound is false then
		set lastPages to {nowPage, nowPage}
	end if
	
	set lastPagesAll to emptyList
	return lastPages
end getRightDoc

----------- Set Current Page for Document -----------
-------------------------------------------------------------
on setPage(thePage)
	try
		tell application "Skim"
			set current page of document 1 to page thePage of document 1
		end tell
		return 0
	on error
		return -1
	end try
end setPage

----- Handler allowing external script -----
------- to pause and restart MacFlip -------
on TogglePause()
	if pauseMacFlip is false then
		set pauseMacFlip to true
		tell application "System Events"
			activate
			try
				do shell script "afplay '/System/Library/Sounds/Submarine.aiff'"
			on error
				beep 2
			end try
			display dialog ("SkimFlip:  " & "OFF (paused)") buttons {"OK"} default button 1 giving up after 1 with icon iconPathDim
			quit
		end tell
	else
		try
			do shell script "afplay '/System/Library/Sounds/Blow.aiff'"
		on error
			beep
		end try
		tell application "System Events"
			activate
			display dialog ("SkimFlip:  " & "ON (reactivated)") buttons {"OK"} default button 1 giving up after 1 with icon iconPath
			quit
		end tell
		set pauseMacFlip to false
	end if
	
	return
end TogglePause


----- Handler allowing external script -----
------- to pause and restart MacFlip -------
on TogglePageTurn()
	if manTurnPages is false then
		set manTurnPages to true
		tell application "System Events"
			activate
			try
				do shell script "afplay '/System/Library/Sounds/Frog.aiff'"
			on error
				beep 2
			end try
			display dialog "Turn Pages with Stylus" buttons {"OK"} default button 1 giving up after 1 with icon iconPath
			quit
		end tell
	else
		try
			do shell script "afplay '/System/Library/Sounds/Purr.aiff'"
		on error
			beep
		end try
		tell application "System Events"
			activate
			display dialog "Turn Pages by Tilting" buttons {"OK"} default button 1 giving up after 1 with icon iconPath
			quit
		end tell
		set manTurnPages to false
	end if
	
	return
end TogglePageTurn

on debug()
	--global smsutilPath, orientCheckDelay, sinIgnore, sinHiTilt, sinFlip, cosFlip, systemInfo, notebookOrient, notebookTilt, documentOrient, pauseMacFlip, tiltCount, lastPage, lastPageCount, lastPages, lastPagesAll, wasFacing, iconPath, iconPathDim, manTurnPages
	
	set notebookTiltS to "notebookTilt:  " & (notebookTilt as string) & return
	set tiltCountS to "tiltCount:  " & (tiltCount as string) & return
	set indexS to "PageNum:  " & (manTurnPages as string) & return
	display dialog notebookTiltS & tiltCountS & manTurnPagesS
end debug