--
--  QTagAppDelegate.applescript
--  QuickTag
--
--  Created by Ryan Ruel on 12/14/13.
--  Copyright (c) 2013 Ryan Ruel. All rights reserved.
--

script QTagAppDelegate
	property parent : class "NSObject"
	
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened 
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
end script