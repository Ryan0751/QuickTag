--
--  QTagAppDelegate.applescript
--  QuickTag
--
--  Created by Ryan Ruel on 12/14/13.
--  Copyright (c) 2013 Ryan Ruel. All rights reserved.
--

script QTagAppDelegate
	property parent : class "NSObject"
    property myTitle : "Custom Tagger"
    property currentTrack : missing value
    property currentGenre : missing value
    property currentComment : missing value
    property genreComboBox : missing value
    property ratingSelector : missing value
    property commentPreview : missing value
    
    property categoryHot : missing value
    property categoryMedium : missing value
    property categoryMild : missing value
    property categoryChill : missing value
    
    property attributeDark : missing value
    property attributeFullVocal : missing value
    property attributeLightVocal : missing value
    property attributeGroover : missing value
    property attributeTribal : missing value
    property attributeUpbeat : missing value
    
	on applicationWillFinishLaunching_(aNotification)
		-- Ensure iTunes is in a proper state
        if (accessHook() is false) then
            try
                tell me to quit
                on error m
                log m
                return
            end try
        end if
              
        -- Start the idle loop to poll for user changes in iTunes
        idleLoop_(.5) -- Interval in seconds
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    to checkItunesIsActive()
        tell application "iTunes" to return running
    end checkItunesIsActive

    on itunesIsNotAccesible()
        try
            with timeout of 1 second
            tell application id "com.apple.iTunes" to get name of library playlist 1
        end timeout
        on error
            return true
        end try
        return false
    end itunesIsNotAccesible

    on isFullScreen()
        try
            tell application "System Events"
                tell process "iTunes"
                    return (get value of attribute "AXFullScreen" of window 1)
                end tell
            end tell
            on error
            return false
        end try
    end isFullScreen

   on accessHook()
       if my checkItunesIsActive() is false then
           set opt to (display dialog "iTunes is not running." buttons {"OK"} default button 1 with title "Cannot proceed..." with icon 0 giving up after 30)
           return false
       end if
       
       if my itunesIsNotAccesible() is true then
           set opt to (display dialog "Close any utility windows that may be open in iTunes." buttons {"OK"} default button 1 with title "Cannot proceed..." with icon 0 giving up after 30)
           return false
       end if
       
       if my isFullScreen() then
           log "iTUNES IS IN FULL SCREEN MODE"
           delay 0.5
           set opt to (display alert "iTunes is in full screen mode." message "This applet's interface cannot be displayed with iTunes while in full screen mode.
           
           You can Quit and re-launch this applet after taking iTunes out of full screen mode.
           
           Or you can Proceed Anyway, but iTunes will not be visible while the applet is running." buttons {"Quit", "Proceed Anyway"} default button 1 as warning giving up after 30)
           if button returned of opt is "quit" then
               tell application "iTunes" to activate
               return false
           end if
       end if
       
       return true
   end accessHook

   on idleLoop_(secsDelay)
        tell application "iTunes"
            -- Look for a selected track
            if selection of front browser window is not {} then
                copy name of current track to newTrackName
                copy genre of current track to newGenre
                copy comment of current track to newComment
                copy rating of current track to newRating
                
                set displayedTrack to currentTrack's stringValue
                set displayedGenre to currentGenre's stringValue
                set displayedComment to currentComment's stringValue
                
                -- Detect a change in any of the display values and update the interface
                if newTrackName is not equal to displayedTrack as string then
                    currentTrack's setStringValue_(newTrackName)
                    
                    -- For a new track name, we will also refresh the "new tags"
                    -- so they will remain the same unless the user changes them.
                    if newGenre contains "Deep House" then
                        genreComboBox's setStringValue_("Deep House")
                    else if newGenre contains "Electro" then
                        genreComboBox's setStringValue_("Electro")
                    else if newGenre contains "Indie" then
                        genreComboBox's setStringValue_("Indie")
                    else if newGenre contains "Progressive" then
                        genreComboBox's setStringValue_("Progressive")
                    else if newGenre contains "Tech House" then
                        genreComboBox's setStringValue_("Tech House")
                    else if newGenre contains "House" then
                        genreComboBox's setStringValue_("House")
                    else if newGenre contains "Techno" then
                        genreComboBox's setStringValue_("Techno")
                    else if newGenre contains "Tool" then
                        genreComboBox's setStringValue_("Tool")
                    end if
                    
                    ratingSelector's setDoubleValue_(newRating / 20)
                    
                    categoryHot's setIntegerValue_(0)
                    categoryMedium's setIntegerValue_(0)
                    categoryMild's setIntegerValue_(0)
                    categoryChill's setIntegerValue_(0)
                    if newComment contains "[Hot]" then
                        categoryHot's setIntegerValue_(1)
                    else if newComment contains "[Medium]" then
                        categoryMedium's setIntegerValue_(1)
                    else if newComment contains "[Mild]" then
                        categoryMild's setIntegerValue_(1)
                    else if newComment contains "[Chill]" then
                        categoryChill's setIntegerValue_(1)
                    end if
                    
                    attributeDark's setIntegerValue_(0)
                    attributeFullVocal's setIntegerValue_(0)
                    attributeLightVocal's setIntegerValue_(0)
                    attributeGroover's setIntegerValue_(0)
                    attributeTribal's setIntegerValue_(0)
                    attributeUpbeat's setIntegerValue_(0)
                    if newComment contains "[Dark]" then
                        attributeDark's setIntegerValue_(1)
                    end if
                    if newComment contains "[Full Vocal]" then
                        attributeFullVocal's setIntegerValue_(1)
                    end if
                    if newComment contains "[Light Vocal]" then
                        attributeLightVocal's setIntegerValue_(1)
                    end if
                    if newComment contains "[Groover]" then
                        attributeGroover's setIntegerValue_(1)
                    end if
                    if newComment contains "[Tribal]" then
                        attributeTribal's setIntegerValue_(1)
                    end if
                    if newComment contains "[Upbeat]" then
                        attributeUpbeat's setIntegerValue_(1)
                    end if
                        
                end if
                
                if newGenre is not equal to displayedGenre as string then
                    currentGenre's setStringValue_(newGenre)
                end if
                
                if newComment is not equal to displayedComment as string then
                    currentComment's setStringValue_(newComment)
                end if
                
                -- Repopulate the comment preview, as this value is used in the final apply
                set nPc to ""
                
                if (categoryHot's integerValue) then
                    set nPc to nPc & "[Hot],"
                else if (categoryMedium's integerValue) then
                    set nPc to nPc & "[Medium],"
                else if (categoryMild's integerValue) then
                    set nPc to nPc & "[Mild],"
                else if (categoryChill's integerValue) then
                    set nPc to nPc & "[Chill],"
                end if
                
                if (attributeDark's integerValue) then
                    set nPc to nPc & "[Dark],"
                end if
                if (attributeFullVocal's integerValue) then
                    set nPc to nPc & "[Full Vocal],"
                end if
                if (attributeLightVocal's integerValue) then
                    set nPc to nPc & "[Light Vocal],"
                end if
                if (attributeGroover's integerValue) then
                    set nPc to nPc & "[Groover],"
                end if
                if (attributeTribal's integerValue) then
                    set nPc to nPc & "[Tribal],"
                end if
                if (attributeUpbeat's integerValue) then
                    set nPc to nPc & "[Upbeat],"
                end if
                
                if nPc is not "" then
                    if (the last character of nPc is ",") then set nPc to text 1 thru ((length of nPc) - 1) of nPc as text
                end if
     
                
                set nPc to nPc & "\n\nTagged with QuickTag"
          
                commentPreview's setStringValue_(nPc)
              
            end if
        end tell
        
        
        -- Update the interface if the current track differs from what we are displaying now
        -- if currentTrack's getStringValue_() is not curTrack
        
           -- currentGenre's setStringValue_(curGenre)
        -- end if
    

        -- Restart our idle timer
        performSelector_withObject_afterDelay_("idleLoop:", secsDelay, secsDelay)
    end idleLoop_


    -- Apply button clicked, update the genre (if set), comments (if set) and
    -- rating.
    on applyChanges_(sender)
        tell application "iTunes"
            set newGenre to genreComboBox's stringValue as text
            if newGenre is not "" then
               set genre of current track to "[" & newGenre & "]"
            end if
        
            set rating of current track to ratingSelector's doubleValue() * 20
            
            set newComment to (commentPreview's stringValue as text)
            if newComment is not "" then
                set comment of current track to (commentPreview's stringValue as text)
            end if
        end tell
    end applyChanges

end script