-- Native Movie > Replace adapter. Tested interaction pattern: English Keynote 14.4.
-- argv: exact review-copy path, slide, movie path, duration stamp, poster stamp, fraction.
-- Do not issue Keynote AppleEvents or synchronous saves while an import sheet exists.
on exactDocument(docPath)
 tell application "Keynote"
  repeat with candidate in documents
   try
    set nativeFile to file of candidate
    set nativePath to POSIX path of nativeFile
    if nativePath is docPath then return candidate
   end try
  end repeat
 end tell
 error "The exact review-copy document is not open"
end exactDocument

on checkMoviePane(docName, endTime, posterTime)
 tell application "System Events" to tell process "Keynote"
  if exists sheet 1 of window docName then error "Unexpected sheet before inspecting movie settings"
  set pane to scroll area 1 of window docName
  set fields to value of every text field of pane
  if item 1 of fields is not "00:00:00.000" then error "Incorrect trim start"
  if item 2 of fields is not endTime then error "Incorrect trim end: " & item 2 of fields
  if item 3 of fields is not posterTime then error "Poster did not persist: " & item 3 of fields
  if value of checkbox "Start movie on click" of pane is not 0 then error "Autoplay is off"
  if value of checkbox "Play movie across slides" of pane is not 0 then error "Cross-slide playback is on"
 end tell
end checkMoviePane

on run argv
 set docPath to item 1 of argv
 set slideIndex to (item 2 of argv) as integer
 set moviePath to item 3 of argv
 set endTime to item 4 of argv
 set posterTime to item 5 of argv
 set posterFraction to (item 6 of argv) as real
 if posterFraction < 0 or posterFraction >= 1 then error "Poster fraction outside [0,1)"
 with timeout of 15 seconds
  set d to my exactDocument(docPath)
  tell application "Keynote"
   activate
   set docName to name of d
   set s to slide slideIndex of d
   if (count of movies of s) is not 1 then error "Expected one existing native movie"
   set tp to transition properties of s
   if automatic transition of tp then error "Automatic slide advance is outside this manual-advance recipe"
   set m to movie 1 of s
   set originalPosition to position of m
   set originalWidth to width of m
   set originalHeight to height of m
   set current slide of d to s
   set selection of d to {m}
  end tell
 end timeout
 tell application "System Events" to tell process "Keynote"
  set frontmost to true
  if exists sheet 1 of window docName then error "Unexpected modal: inspect the review copy before retrying"
  click radio button 2 of radio group 1 of window docName
  if not (exists button "Replace" of scroll area 1 of window docName) then error "Expected English Movie inspector with Replace button"
  click button "Replace" of scroll area 1 of window docName
  repeat 50 times
   if exists sheet 1 of window docName then exit repeat
   delay 0.1
  end repeat
  if not (exists sheet 1 of window docName) then error "Movie file picker did not open"
  keystroke "g" using {command down, shift down}
  repeat 40 times
   if exists sheet 1 of sheet 1 of window docName then exit repeat
   delay 0.1
  end repeat
  if not (exists sheet 1 of sheet 1 of window docName) then error "Go to Folder did not open"
  click text field 1 of sheet 1 of sheet 1 of window docName
  keystroke "a" using command down
  set value of text field 1 of sheet 1 of sheet 1 of window docName to moviePath
  -- AX assignment avoids dropped characters; a reversible edit commits the value.
  key code 124
  keystroke "x"
  key code 51
  delay 0.5
  key code 36
  repeat 40 times
   if not (exists sheet 1 of sheet 1 of window docName) then exit repeat
   delay 0.1
  end repeat
  if not (enabled of button "Insert" of splitter group 1 of sheet 1 of window docName) then error "Movie file was not selected"
  click button "Insert" of splitter group 1 of sheet 1 of window docName
  set clearedWarning to false
  set steadyChecks to 0
  repeat 100 times
   if exists sheet 1 of window docName then
    set steadyChecks to 0
    set labels to value of static texts of sheet 1 of window docName
    if (labels as text) contains "This movie may not play" then
     if not (exists button "OK" of sheet 1 of window docName) then error "Compatibility sheet has an unexpected action"
     click button "OK" of sheet 1 of window docName
     set clearedWarning to true
    else
     error "Unexpected Keynote import dialog: " & (labels as text)
    end if
   else
    if exists text field 2 of scroll area 1 of window docName then set steadyChecks to steadyChecks + 1
    if steadyChecks > 12 then exit repeat
   end if
   delay 0.2
  end repeat
  if (exists sheet 1 of window docName) or steadyChecks <= 12 then error "Import did not settle"
  set pane to scroll area 1 of window docName
  click text field 1 of pane
  set value of text field 1 of pane to "00:00:00.000"
  key code 36
  click text field 2 of pane
  set value of text field 2 of pane to endTime
  key code 36
  -- Typing a poster time may look correct without changing the saved poster.
  set value of slider 2 of pane to posterFraction
  if value of checkbox "Start movie on click" of pane is 1 then click checkbox "Start movie on click" of pane
  if value of checkbox "Play movie across slides" of pane is 1 then click checkbox "Play movie across slides" of pane
 end tell
 my checkMoviePane(docName, endTime, posterTime)
 with timeout of 15 seconds
  set d to my exactDocument(docPath)
  tell application "Keynote"
   set m to movie 1 of slide slideIndex of d
   if position of m is not originalPosition or width of m is not originalWidth or height of m is not originalHeight then error "Movie geometry changed"
   -- Empty native selections are rejected by some Keynote versions.
   tell application "System Events" to tell process "Keynote" to key code 53
   set selection of d to {m}
   set tp to transition properties of slide slideIndex of d
   if automatic transition of tp then error "Unexpected automatic slide advance"
  end tell
 end timeout
 delay 0.3
 tell application "System Events" to tell process "Keynote"
  click radio button 2 of radio group 1 of window docName
 end tell
 my checkMoviePane(docName, endTime, posterTime)
 tell application "System Events" to tell process "Keynote"
  set frontmost to true
  keystroke "s" using command down
 end tell
 -- An AppleScript save here can wait on the import serialization semaphore.
 -- UI Save is used instead; the Python caller verifies the saved media bytes.
 return "slide=" & slideIndex & "; trim=full; poster=" & posterTime & "; autoplay=true; manual-advance=true; geometry-preserved=true; compatibility-warning=" & clearedWarning
end run
