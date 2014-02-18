--
--  QTagAppDelegate.applescript
--  QuickTag
--
--  Created by Ryan Ruel on 12/14/13.
--  Copyright (c) 2014 Ryan Ruel. All rights reserved.
--

script QTagAppDelegate
	property parent : class "NSObject"
    property myTitle : "QuickTag"
    
    -- Shared user defaults
    property defaults : missing value
    
    -- Limits
    property maxCategories : 8
    property maxAttributes : 18
    
    -- Interface outlets for existing track tags
    property currentTrack : missing value
    property currentGenre : missing value
    property currentComment : missing value
    
    -- Interface outlets for the newly selected
    property genreComboBox : missing value
    property ratingSelector : missing value
    property commentPreview : missing value
    
    property categoryOne : missing value
    property categoryTwo : missing value
    property categoryThree : missing value
    property categoryFour : missing value
    property categoryFive : missing value
    property categorySix : missing value
    property categorySeven : missing value
    property categoryEight : missing value
    
    property attributeOne : missing value
    property attributeTwo : missing value
    property attributeThree : missing value
    property attributeFour : missing value
    property attributeFive : missing value
    property attributeSix : missing value
    property attributeSeven : missing value
    property attributeEight : missing value
    property attributeNine : missing value
    property attributeTen : missing value
    property attributeEleven : missing value
    property attributeTwelve : missing value
    property attributeThirteen : missing value
    property attributeFourteen : missing value
    property attributeFifteen : missing value
    property attributeSixteen : missing value
    property attributeSeventeen : missing value
    property attributeEighteen : missing value
    
    -- Array controllers for the configurable lists in user preferences
    property genreArrayController : missing value
    property categoryArrayController : missing value
    property attributeArrayController : missing value
    
    -- Save values so that we can revert the user changes if requested
    property savedName : missing value
    property savedGenre : missing value
    property savedRating : missing value
    property savedComment : missing value
    
    -- The lists of genres, categories and attributes, broken out from the arrays
    -- for easier access.
    property genreList : missing value
    property categoryList : missing value
    property attributeList : missing value
    
    -- Interface outlets for the delimiters
    property genreStartDelimiter : missing value
    property genreEndDelimiter : missing value
    property categoryStartDelimiter : missing value
    property categoryEndDelimiter : missing value
    property attributeStartDelimiter : missing value
    property attributeEndDelimiter : missing value
    property ratingStartDelimiter : missing value
    property ratingEndDelimiter : missing value
    
    -- Additional tagline outlet
    property tagLine : missing value
    
    -- Where to write track comments (outlets from user prefs)
    property commentsDestination : missing value
    property commentsOverwrite : missing value
    property commentsPrepend : missing value
    property commentsAppend : missing value
    
    -- Our main idle loop delay period, this should be low enough to make the app appear
    -- dynamic, but not so low as to impact performance.
    property idleLoopDelay : .5
    
    --
    -- Application launch
    --
	on applicationWillFinishLaunching_(aNotification)
		-- Ensure iTunes is in a proper state for us to run
        if (accessHook() is false) then
            try
                tell me to quit
                on error m
                log m
                return
            end try
        end if
        
        -- Register standard user defaults
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        
        set genreDefaults to {{genre:"Genre 1"},{genre:"Genre 2"}, {genre:"Genre 3"}}
        set categoryDefaults to {{category:"Category 1"},{category:"Category 2"}, {category:"Category 3"}}
        set attributeDefaults to {{attribute:"Attribute 1"},{attribute:"Attribute 2"}, {attribute:"Attribute 3"}}
        
        log "Registering user defaults"
        tell defaults to registerDefaults_({tagDestination:"Overwrite existing comments", genreStartDelim:"(", genreEndDelim:")", ratingStartDelim:"<", ratingEndDelim:">", categoryStartDelim:"{", categoryEndDelim:"}", attributeStartDelim:"[", attributeEndDelim:"]", customTagline:"Tagged with QuickTag", genres:genreDefaults, categories:categoryDefaults, attributes:attributeDefaults})
        
        -- Apply preferences to grab the current configured values and refresh the interface
        applyPreferences_(me)
              
        -- Start the idle loop, which is the event loop for all application events
    idleLoop_(idleLoopDelay) -- Interval in seconds
	end applicationWillFinishLaunching_
	
    --
    -- Application termination
    --
	on applicationShouldTerminate_(sender)
        log "Application terminating"
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    --
    -- Check if iTunes is active
    --
    to checkItunesIsActive()
        tell application "iTunes" to return running
    end checkItunesIsActive

    --
    -- Check if iTunes is accessible
    --
    on itunesIsNotAccesible()
        try
            with timeout of 10 seconds
                tell application id "com.apple.iTunes" to get name of library playlist 1
            end timeout
        on error
            log ("ERROR: itunesIsNotAccesible() - could not get playlist name.")
            return true
        end try
        return false
    end itunesIsNotAccesible

    --
    -- Check if iTunes is runninng full-screen
    --
    on isFullScreen()
        try
            tell application "System Events"
                tell process "iTunes"
                    return (get value of attribute "AXFullScreen" of window 1)
                end tell
            end tell
            on error
                log ("iTunes is not in full-screen mode")
                return false
        end try
    end isFullScreen

    --
    -- Ensure that iTunes is in a state we can work with
    --
    on accessHook()
       if my checkItunesIsActive() is false then
           -- Start the application if not running
           tell application "iTunes" to activate
           return true
       end if
       
       if my itunesIsNotAccesible() is true then
           set opt to (display dialog "Please close any utility windows that may be open in iTunes" buttons {"OK"} default button 1 with title "Cannot proceed..." with icon 0 giving up after 30)
           return false
       end if
       
       if my isFullScreen() then
           log "iTunes is in full screen mode"
           delay 0.5
           set opt to (display alert "iTunes is in full screen mode" message "This applet's interface cannot be displayed with iTunes while in full screen mode.
           
           You can Quit and re-launch this application after taking iTunes out of full screen mode.
           
           Or you can Proceed Anyway, but iTunes will not be visible while the applet is running." buttons {"Quit", "Proceed Anyway"} default button 1 as warning giving up after 30)
           if button returned of opt is "quit" then
               tell application "iTunes" to activate
               return false
           end if
       end if
       
       return true
   end accessHook

   --
   -- The main event loop for the application.  We have to poll iTunes as we don't have a
   -- way to receive asynchronous events from it.
   --
   on idleLoop_(secsDelay)
        set selectedTrackName to ""
        try
            tell application "iTunes"
                -- Look for a selected track
                if selection of front browser window is not {} then
                    log "Grabbing tag values from the iTunes track browser"
                    -- Copy values to our properties for use later
                    copy name of current track to selectedTrackName
                    copy genre of current track to selectedTrackGenre
                    copy rating of current track to selectedTrackRating
                    copy comment of current track to selectedTrackComment
                else
                    set selectedTrackName to ""
                end if
            end tell
        on error errorMessage number errorNumber
            log ("ERROR: idleLoop_() get selected track - " & errorMessage & ", errorNumber: " & errorNumber)
        end try
        
        -- We have a track selected
        if selectedTrackName is not ""
            -- Grab the tag values currently in the interface
            set displayedTrack to currentTrack's stringValue
            set displayedGenre to currentGenre's stringValue
            set displayedComment to currentComment's stringValue
            
            -- Our trigger for handling a track change is when the displayed track name differs
            -- from the track name in iTunes.
            if selectedTrackName is not equal to displayedTrack as string then
                log "New track selected: " & selectedTrackName
                -- Save the original values
                set savedName to selectedTrackName
                set savedGenre to selectedTrackGenre
                set savedRating to selectedTrackRating
                set savedComment to selectedTrackComment
              
                -- Display the new track name
                currentTrack's setStringValue_(selectedTrackName)
                
                -- Update all of the new tag selection values
                refreshNewTagSelectors()
                
            end if
            
            if selectedTrackGenre is not equal to displayedGenre as string then
                currentGenre's setStringValue_(selectedTrackGenre)
            end if
            
            if selectedTrackComment is not equal to displayedComment as string then
                currentComment's setStringValue_(selectedTrackComment)
            end if
            
            -- Grab the delimiter values from the user interface
            set genreSd to genreStartDelimiter's stringValue as text
            set genreEd to genreEndDelimiter's stringValue as text
            set categorySd to categoryStartDelimiter's stringValue as text
            set categoryEd to categoryEndDelimiter's stringValue as text
            set attributeSd to attributeStartDelimiter's stringValue as text
            set attributeEd to attributeEndDelimiter's stringValue as text
            set ratingSd to ratingStartDelimiter's stringValue as text
            set ratingEd to ratingEndDelimiter's stringValue as text
            
            -- Repopulate the comment preview, as this value is used in the final apply
            set nPc to ""
            
            set nPc to nPc & ratingSd & "Rating " & ratingSelector's integerValue() & ratingEd & ","
            
            if (categoryOne's integerValue) then
                set nPc to nPc & categorySd & (item 1 of categoryList) & categoryEd & ","
            else if (categoryTwo's integerValue) then
                set nPc to nPc & categorySd & (item 2 of categoryList) & categoryEd & ","
            else if (categoryThree's integerValue) then
                set nPc to nPc & categorySd & (item 3 of categoryList) & categoryEd & ","
            else if (categoryFour's integerValue) then
                set nPc to nPc & categorySd & (item 4 of categoryList) & categoryEd & ","
            else if (categoryFive's integerValue) then
                set nPc to nPc & categorySd & (item 5 of categoryList) & categoryEd & ","
            else if (categorySix's integerValue) then
                set nPc to nPc & categorySd & (item 6 of categoryList) & categoryEd & ","
            else if (categorySeven's integerValue) then
                set nPc to nPc & categorySd & (item 7 of categoryList) & categoryEd & ","
            else if (categoryEight's integerValue) then
                set nPc to nPc & categorySd & (item 8 of categoryList) & categoryEd & ","
            end if
            
            if (attributeOne's integerValue) then
                set nPc to nPc & attributeSd & (item 1 of attributeList) & attributeEd & ","
            end if
            if (attributeTwo's integerValue) then
                set nPc to nPc & attributeSd & (item 2 of attributeList) & attributeEd & ","
            end if
            if (attributeThree's integerValue) then
                set nPc to nPc & attributeSd & (item 3 of attributeList) & attributeEd & ","
            end if
            if (attributeFour's integerValue) then
                set nPc to nPc & attributeSd & (item 4 of attributeList) & attributeEd & ","
            end if
            if (attributeFive's integerValue) then
                set nPc to nPc & attributeSd & (item 5 of attributeList) & attributeEd & ","
            end if
            if (attributeSix's integerValue) then
                set nPc to nPc & attributeSd & (item 6 of attributeList) & attributeEd & ","
            end if
            if (attributeSeven's integerValue) then
                set nPc to nPc & attributeSd & (item 7 of attributeList) & attributeEd & ","
            end if
            if (attributeEight's integerValue) then
                set nPc to nPc & attributeSd & (item 8 of attributeList) & attributeEd & ","
            end if
            if (attributeNine's integerValue) then
                set nPc to nPc & attributeSd & (item 9 of attributeList) & attributeEd & ","
            end if
            if (attributeTen's integerValue) then
                set nPc to nPc & attributeSd & (item 10 of attributeList) & attributeEd & ","
            end if
            if (attributeEleven's integerValue) then
                set nPc to nPc & attributeSd & (item 11 of attributeList) & attributeEd & ","
            end if
            if (attributeTwelve's integerValue) then
                set nPc to nPc & attributeSd & (item 12 of attributeList) & attributeEd & ","
            end if
            if (attributeThirteen's integerValue) then
                set nPc to nPc & attributeSd & (item 13 of attributeList) & attributeEd & ","
            end if
            if (attributeFourteen's integerValue) then
                set nPc to nPc & attributeSd & (item 14 of attributeList) & attributeEd & ","
            end if
            if (attributeFifteen's integerValue) then
                set nPc to nPc & attributeSd & (item 15 of attributeList) & attributeEd & ","
            end if
            if (attributeSixteen's integerValue) then
                set nPc to nPc & attributeSd & (item 16 of attributeList) & attributeEd & ","
            end if
            if (attributeSeventeen's integerValue) then
                set nPc to nPc & attributeSd & (item 17 of attributeList) & attributeEd & ","
            end if
            if (attributeEighteen's integerValue) then
                set nPc to nPc & attributeSd & (item 18 of attributeList) & attributeEd & ","
            end if
           
            -- Trim off any trailing commas
            if nPc is not "" then
                if (the last character of nPc is ",") then set nPc to text 1 thru ((length of nPc) - 1) of nPc as text
            end if
 
            set additionalTagLine to tagLine's stringValue as text
            if additionalTagLine is not "" then
                set nPc to nPc & "\n" & additionalTagLine
            end if
            
            if (commentsPrepend's integerValue)
                set nPc to nPc & "\n" & selectedTrackComment
            else if (commentsAppend's integerValue)
                set nPc to selectedTrackComment & "\n" & nPc
            end if
      
            commentPreview's setStringValue_(nPc)
          
        end if

        -- Restart the idle timer
        performSelector_withObject_afterDelay_("idleLoop:", secsDelay, secsDelay)
    end idleLoop_

    --
    -- Refresh the "new" tag selectors such that they reflect the tags in the currently playing track
    --
    on refreshNewTagSelectors()
        try
            tell application "iTunes"
                -- Look for a selected track
                if selection of front browser window is not {} then
                    -- Copy values to our properties
                    copy name of current track to selectedTrackName
                    copy genre of current track to selectedTrackGenre
                    copy rating of current track to selectedTrackRating
                    copy comment of current track to selectedTrackComment
                end if
            end tell
        on error errorMessage number errorNumber
            log ("ERROR: refreshNewTagSelectors() copy existing track tags " & errorMessage & ", errorNumber: " & errorNumber)
        end try
        
        -- Grab the delimiter values
        set genreSd to genreStartDelimiter's stringValue as text
        set genreEd to genreEndDelimiter's stringValue as text
        set categorySd to categoryStartDelimiter's stringValue as text
        set categoryEd to categoryEndDelimiter's stringValue as text
        set attributeSd to attributeStartDelimiter's stringValue as text
        set attributeEd to attributeEndDelimiter's stringValue as text
        set ratingSd to ratingStartDelimiter's stringValue as text
        set ratingEd to ratingEndDelimiter's stringValue as text
        
        -- Refresh the genre combo box
        repeat with theGenre in genreList
            if (selectedTrackGenre is equal to theGenre as string) or (selectedTrackGenre is equal to (genreSd & theGenre & genreEd)) then
                genreComboBox's setStringValue_(theGenre)
                exit repeat
            end if
        end repeat
        
        -- iTunes uses a rating scale up to 100, so we need to divide by 20 to have 5 star slots
        ratingSelector's setDoubleValue_(selectedTrackRating / 20)
        
        categoryOne's setIntegerValue_(0)
        categoryTwo's setIntegerValue_(0)
        categoryThree's setIntegerValue_(0)
        categoryFour's setIntegerValue_(0)
        categoryFive's setIntegerValue_(0)
        categorySix's setIntegerValue_(0)
        categorySeven's setIntegerValue_(0)
        categoryEight's setIntegerValue_(0)
        
        repeat with theCategoryIndex from 1 to count of the categoryList
            if selectedTrackComment contains (categorySd & (item theCategoryIndex of categoryList) & categoryEd) then
                if theCategoryIndex is 1 then
                    categoryOne's setIntegerValue_(1)
                else if theCategoryIndex is 2 then
                    categoryTwo's setIntegerValue_(1)
                else if theCategoryIndex is 3 then
                    categoryThree's setIntegerValue_(1)
                else if theCategoryIndex is 4 then
                    categoryFour's setIntegerValue_(1)
                else if theCategoryIndex is 5 then
                    categoryFive's setIntegerValue_(1)
                else if theCategoryIndex is 6 then
                    categorySix's setIntegerValue_(1)
                else if theCategoryIndex is 7 then
                    categorySeven's setIntegerValue_(1)
                else if theCategoryIndex is 8 then
                    categoryEight's setIntegerValue_(8)
                end if
            end if
        end repeat
        
        attributeOne's setIntegerValue_(0)
        attributeTwo's setIntegerValue_(0)
        attributeThree's setIntegerValue_(0)
        attributeFour's setIntegerValue_(0)
        attributeFive's setIntegerValue_(0)
        attributeSix's setIntegerValue_(0)
        attributeSeven's setIntegerValue_(0)
        attributeEight's setIntegerValue_(0)
        attributeNine's setIntegerValue_(0)
        attributeTen's setIntegerValue_(0)
        attributeEleven's setIntegerValue_(0)
        attributeTwelve's setIntegerValue_(0)
        attributeThirteen's setIntegerValue_(0)
        attributeFourteen's setIntegerValue_(0)
        attributeFifteen's setIntegerValue_(0)
        attributeSixteen's setIntegerValue_(0)
        attributeSeventeen's setIntegerValue_(0)
        attributeEighteen's setIntegerValue_(0)
        
        repeat with theAttributeIndex from 1 to count of the attributeList
            try
                if selectedTrackComment contains (attributeSd & (item theAttributeIndex of attributeList) & attributeEd) then
                    if theAttributeIndex is 1 then
                        attributeOne's setIntegerValue_(1)
                    else if theAttributeIndex is 2 then
                        attributeTwo's setIntegerValue_(1)
                    else if theAttributeIndex is 3 then
                        attributeThree's setIntegerValue_(1)
                    else if theAttributeIndex is 4 then
                        attributeFour's setIntegerValue_(1)
                    else if theAttributeIndex is 5 then
                        attributeFive's setIntegerValue_(1)
                    else if theAttributeIndex is 6 then
                        attributeSix's setIntegerValue_(1)
                    else if theAttributeIndex is 7 then
                        attributeSeven's setIntegerValue_(1)
                    else if theAttributeIndex is 8 then
                        attributeEight's setIntegerValue_(1)
                    else if theAttributeIndex is 9 then
                        attributeNine's setIntegerValue_(1)
                    else if theAttributeIndex is 10 then
                        attributeTen's setIntegerValue_(1)
                    else if theAttributeIndex is 11 then
                        attributeEleven's setIntegerValue_(1)
                    else if theAttributeIndex is 12 then
                        attributeTwelve's setIntegerValue_(1)
                    else if theAttributeIndex is 13 then
                        attributeThirteen's setIntegerValue_(1)
                    else if theAttributeIndex is 14 then
                        attributeFourteen's setIntegerValue_(1)
                    else if theAttributeIndex is 15 then
                        attributeFifteen's setIntegerValue_(1)
                    else if theAttributeIndex is 16 then
                        attributeSixteen's setIntegerValue_(1)
                    else if theAttributeIndex is 17 then
                        attributeSeventeen's setIntegerValue_(1)
                    else if theAttributeIndex is 18 then
                        attributeEighteen's setIntegerValue_(1)
                    end if
                end if
            on error errorMessage number errorNumber
                log ("ERROR: refreshNewTagSelectors() set attributes - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
        end repeat

    end refreshNewTagSelectors

    --
    -- Set up the interface based on our genre, category and attribute lists, which
    -- come from the array controllers used in the user preferences.
    --
    on setupInterface()
        log "Setting up the user interface"
        -- Set up the genres
        genreComboBox's removeAllItems()
        genreComboBox's addItemsWithObjectValues_(genreList)
        
        -- Set up the categories
        categoryOne's setTransparent_(1)
        categoryOne's setEnabled_(0)
        categoryTwo's setTransparent_(1)
        categoryTwo's setEnabled_(0)
        categoryThree's setTransparent_(1)
        categoryThree's setEnabled_(0)
        categoryFour's setTransparent_(1)
        categoryFour's setEnabled_(0)
        categoryFive's setTransparent_(1)
        categoryFive's setEnabled_(0)
        categorySix's setTransparent_(1)
        categorySix's setEnabled_(0)
        categorySeven's setTransparent_(1)
        categorySeven's setEnabled_(0)
        categoryEight's setTransparent_(1)
        categoryEight's setEnabled_(0)
        
        repeat with theCategoryIndex from 1 to count of the categoryList
            if theCategoryIndex is 1 then
                categoryOne's setTransparent_(0)
                categoryOne's setEnabled_(1)
                categoryOne's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 2 then
                categoryTwo's setTransparent_(0)
                categoryTwo's setEnabled_(1)
                categoryTwo's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 3 then
                categoryThree's setTransparent_(0)
                categoryThree's setEnabled_(1)
                categoryThree's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 4 then
                categoryFour's setTransparent_(0)
                categoryFour's setEnabled_(1)
                categoryFour's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 5 then
                categoryFive's setTransparent_(0)
                categoryFive's setEnabled_(1)
                categoryFive's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 6 then
                categorySix's setTransparent_(0)
                categorySix's setEnabled_(1)
                categorySix's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 7 then
                categorySeven's setTransparent_(0)
                categorySeven's setEnabled_(1)
                categorySeven's setTitle_(item theCategoryIndex of categoryList)
            else if theCategoryIndex is 8 then
                categoryEight's setTransparent_(0)
                categoryEight's setEnabled_(1)
                categoryEight's setTitle_(item theCategoryIndex of categoryList)
            end if
        end repeat
        
        -- Set up the attributes
        attributeOne's setTransparent_(1)
        attributeOne's setEnabled_(0)
        attributeTwo's setTransparent_(1)
        attributeTwo's setEnabled_(0)
        attributeThree's setTransparent_(1)
        attributeThree's setEnabled_(0)
        attributeFour's setTransparent_(1)
        attributeFour's setEnabled_(0)
        attributeFive's setTransparent_(1)
        attributeFive's setEnabled_(0)
        attributeSix's setTransparent_(1)
        attributeSix's setEnabled_(0)
        attributeSeven's setTransparent_(1)
        attributeSeven's setEnabled_(0)
        attributeEight's setTransparent_(1)
        attributeEight's setEnabled_(0)
        attributeNine's setTransparent_(1)
        attributeNine's setEnabled_(0)
        attributeTen's setTransparent_(1)
        attributeTen's setEnabled_(0)
        attributeEleven's setTransparent_(1)
        attributeEleven's setEnabled_(0)
        attributeTwelve's setTransparent_(1)
        attributeTwelve's setEnabled_(0)
        attributeThirteen's setTransparent_(1)
        attributeThirteen's setEnabled_(0)
        attributeFourteen's setTransparent_(1)
        attributeFourteen's setEnabled_(0)
        attributeFifteen's setTransparent_(1)
        attributeFifteen's setEnabled_(0)
        attributeSixteen's setTransparent_(1)
        attributeSixteen's setEnabled_(0)
        attributeSeventeen's setTransparent_(1)
        attributeSeventeen's setEnabled_(0)
        attributeEighteen's setTransparent_(1)
        attributeEighteen's setEnabled_(0)
        
        repeat with theAttributeIndex from 1 to count of the attributeList
            if theAttributeIndex is 1 then
                attributeOne's setTransparent_(0)
                attributeOne's setEnabled_(1)
                attributeOne's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 2 then
                attributeTwo's setTransparent_(0)
                attributeTwo's setEnabled_(1)
                attributeTwo's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 3 then
                attributeThree's setTransparent_(0)
                attributeThree's setEnabled_(1)
                attributeThree's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 4 then
                attributeFour's setTransparent_(0)
                attributeFour's setEnabled_(1)
                attributeFour's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 5 then
                attributeFive's setTransparent_(0)
                attributeFive's setEnabled_(1)
                attributeFive's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 6 then
                attributeSix's setTransparent_(0)
                attributeSix's setEnabled_(1)
                attributeSix's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 7 then
                attributeSeven's setTransparent_(0)
                attributeSeven's setEnabled_(1)
                attributeSeven's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 8 then
                attributeEight's setTransparent_(0)
                attributeEight's setEnabled_(1)
                attributeEight's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 9 then
                attributeNine's setTransparent_(0)
                attributeNine's setEnabled_(1)
                attributeNine's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 10 then
                attributeTen's setTransparent_(0)
                attributeTen's setEnabled_(1)
                attributeTen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 11 then
                attributeEleven's setTransparent_(0)
                attributeEleven's setEnabled_(1)
                attributeEleven's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 12 then
                attributeTwelve's setTransparent_(0)
                attributeTwelve's setEnabled_(1)
                attributeTwelve's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 13 then
                attributeThirteen's setTransparent_(0)
                attributeThirteen's setEnabled_(1)
                attributeThirteen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 14 then
                attributeFourteen's setTransparent_(0)
                attributeFourteen's setEnabled_(1)
                attributeFourteen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 15 then
                attributeFifteen's setTransparent_(0)
                attributeFifteen's setEnabled_(1)
                attributeFifteen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 16 then
                attributeSixteen's setTransparent_(0)
                attributeSixteen's setEnabled_(1)
                attributeSixteen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 17 then
                attributeSeventeen's setTransparent_(0)
                attributeSeventeen's setEnabled_(1)
                attributeSeventeen's setTitle_(item theAttributeIndex of attributeList)
            else if theAttributeIndex is 18 then
                attributeEighteen's setTransparent_(0)
                attributeEighteen's setEnabled_(1)
                attributeEighteen's setTitle_(item theAttributeIndex of attributeList)
            end if
        end repeat
    end setupInterface

    --
    -- Apply button clicked, update track tags in iTunes
    --
    on applyChanges_(sender)
        log "Applying changes for track: " & savedName
        
        -- Grab the delimiter values
        set genreSd to genreStartDelimiter's stringValue as text
        set genreEd to genreEndDelimiter's stringValue as text

        try
            tell application "iTunes"
                set newGenre to genreComboBox's stringValue as text
                if newGenre is not "" then
                   set genre of current track to genreSd & newGenre & genreEd
                end if
            
                -- Multiply rating by 20 to get it in a scale of 1-100 for iTunes
                set rating of current track to ratingSelector's doubleValue() * 20
                
                set newComment to (commentPreview's stringValue as text)
                if newComment is not "" then
                    set comment of current track to (commentPreview's stringValue as text)
                end if
            end tell
        on error errorMessage number errorNumber
            log ("ERROR: applyChanges_() - " & errorMessage & ", errorNumber: " & errorNumber)
        end try
    end applyChanges

    --
    -- Revert button clicked, revert to original tag values
    --
    on revertChanges_(sender)
        set opt to (display alert "Revert Changes?" message "Revert track tags to the original values?" buttons {"Cancel", "Revert"} default button 1 as warning giving up after 30)
        if button returned of opt is "Revert" then
            log "Reverting changes for track: " & savedName
            try
                tell application "iTunes"
                    set genre of current track to savedGenre
                    set rating of current track to savedRating
                    set comment of current track to savedComment
                end tell
            on error errorMessage number errorNumber
                log ("ERROR: revertChanges_() - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
            refreshNewTagSelectors()
            return true
        else
            log "Revert cancelled"
        end if
    end revertChanges

    --
    -- Can we add a new category callback
    --
    on canAddCategory_()
        set newCategories to (categoryArrayController's arrangedObjects()) as list
        if count of newCategories is greater than or equal to maxCategories then
            log "Cannot add any more categories"
            return 0
        end if
        
        return 1
    end canAddCategory

    --
    -- Can we add a new attribute callback
    --
    on canAddAttribute_()
        set newAttributes to (attributeArrayController's arrangedObjects()) as list
        if count of newAttributes is greater than or equal to maxAttributes then
            log "Cannot add any more attributes"
            return 0
        end if

        return 1
    end canAddAttribute

    --
    -- Apply preferences button clicked, update the interface
    --
    on applyPreferences_(sender)
        log "Applying user preferences"
        
        set newGenres to (genreArrayController's arrangedObjects()) as list
        if count of newGenres is not 0 then
            set genreList to {}
        end if
        repeat with aGenre in newGenres
            try
                set theName to genre of aGenre
                set genreList to genreList & theName
            on error errorMessage number errorNumber
                log ("ERROR: applyPreferences_() genre - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
        end repeat
                
        set newCategories to (categoryArrayController's arrangedObjects()) as list
        if count of newCategories is greater than maxCategories then
            display alert "QuickTag only supports up to " & maxCategories & " categories.\n\nOnly the first " & maxCategories & " will be displayed."
        end if
        if count of newCategories is not 0 then
            set categoryList to {}
        end if
        repeat with aCategory in newCategories
            try
                set theCategory to category of aCategory
                set categoryList to categoryList & theCategory
            on error errorMessage number errorNumber
                log ("ERROR: applyPreferences_() category - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
        end repeat
        
        set newAttributes to (attributeArrayController's arrangedObjects()) as list
        if count of newAttributes is greater than maxAttributes then
            display alert "QuickTag only supports up to " & maxAttributes & " attributes.\n\nOnly the first " & maxAttributes & " will be displayed."
        end if
        if count of newAttributes is not 0 then
            set attributeList to {}
        end if
        repeat with aAttribute in newAttributes
            try
                set theAttribute to attribute of aAttribute
                set attributeList to attributeList & theAttribute
            on error errorMessage number errorNumber
                log ("ERROR: applyPreferences_() attribute - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
        end repeat
        
        -- Finally refresh our interface with the new values
        log "Refreshing user interface with new preferences"
        setupInterface()
    end applyPreferences

    --
    -- Get a list of unique genres, for importing to the genre list
    --
    on importGenres_(sender)
        set opt to (display alert "Import genres from iTunes?" message "Import all existing genres found in existing tracks in iTunes? \n\nThis may take up to several minutes depending on the size of your collection."  buttons {"Cancel", "Import"} default button 1 as warning giving up after 30)
        
        if button returned of opt is "import" then
            log "Importing genre list from iTunes"
            try
                tell application "iTunes"
                    set len to count of tracks
                    repeat with num from 1 to len
                        if num is equal to 1 then set importGenreList to {}
                        set gen to genre of track num
                        if gen is not in importGenreList then copy gen to the end of importGenreList
                    end repeat 
                end tell
            on error errorMessage number errorNumber
                log ("ERROR: importGenres_() - " & errorMessage & ", errorNumber: " & errorNumber)
            end try
            log "Imported genre list: " & importGenrelist
            set tempList to {}
            repeat with i from 1 to count of importGenrelist
                set end of tempList to {genre:item i of importGenrelist}
            end repeat
            tell genreArrayController to addObjects_(tempList)
            
        end if
    end importGenres

end script

-- End of application