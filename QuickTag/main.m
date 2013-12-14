//
//  main.m
//  QuickTag
//
//  Created by Ryan Ruel on 12/14/13.
//  Copyright (c) 2013 Ryan Ruel. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <AppleScriptObjC/AppleScriptObjC.h>

int main(int argc, const char * argv[])
{
    [[NSBundle mainBundle] loadAppleScriptObjectiveCScripts];
    return NSApplicationMain(argc, argv);
}
