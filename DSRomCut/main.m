//
//  main.m
//  DSRomCut
//
//  Created by orix on 10/29/13.
//  Copyright (c) 2013 orix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, const char * argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = NSApplicationMain(argc, argv);
	[pool release];
	return retVal;
}
