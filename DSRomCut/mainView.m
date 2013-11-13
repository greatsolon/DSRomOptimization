//
//  mainView.m
//  DSRomCut
//
//  Created by orix on 10/29/13.
//  Copyright (c) 2013 orix. All rights reserved.
//

#import "mainView.h"

@implementation mainView

@synthesize singleChooseButton = m_singleChooseButton;
@synthesize singleCleanButton = m_singleCleanButton;
@synthesize singleFileText = m_singleFileText;
@synthesize singleLabel = m_singleLabel;
@synthesize singleProgress = m_singleProgress;
@synthesize singleBarText = m_singleBarText;
@synthesize logBox = m_logBox;
@synthesize fileList = m_fileList;

#define BLOCKSIZE 1000000

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		
    }
    return self;
}

- (id)init
{
	if ((self = [super init])) {
		
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	// Draw code here
}

- (IBAction)chooseFiles:(id)sender
{
#ifdef DEBUG
	NSLog(@"Clicked single button.");
#endif
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	[oPanel setCanChooseDirectories:YES];
	[oPanel setCanChooseFiles:YES];
	[oPanel setAllowsMultipleSelection:YES];
	//	[oPanel setDirectory:NSHomeDirectory()];
	if ([oPanel runModal] == NSOKButton) {
		self.fileList = [[[NSMutableArray alloc] initWithArray:[oPanel URLs]] autorelease];
		if (self.fileList && [self.fileList count] > 0) {
			if ([self.fileList count] == 1) {
				NSString* path = [[self.fileList objectAtIndex:0] path];
				[m_singleFileText setStringValue:path];
			} else {
				[m_singleFileText setStringValue:@"Multiple files..."];
			}
		}
	}
}

- (IBAction)optimizationFiles:(id)sender
{
	// Clean all log
	[self cleanLog];
	// Configration logbox
	[m_logBox setTextColor:[NSColor greenColor]];
	// Remove all notification
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationSetFileSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAnalyzeSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationWriteSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAllDone" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAddLog" object:nil];
	// Regiese a notification to set original file size
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(setFileSize:) name:@"kNotificationSetFileSize" object:nil];
	// Regiest a notification to set analyzed file size.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(analyzeSize:) name:@"kNotificationAnalyzeSize" object:nil];
	// Regiest a notification to set file write size.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(setWriteSize:) name:@"kNotificationWriteSize" object:Nil];
	// Regiest a notification to broadcast all done.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(allDone:) name:@"kNotificationAllDone" object:nil];
	// Regiest a notification to set log.
	[[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(setLog:) name:@"kNotificationAddLog" object:nil];
	// Set progress bar
	[m_singleProgress setUsesThreadedAnimation:YES];
	[m_singleProgress startAnimation:nil];
	[m_singleProgress setIndeterminate:NO];
	[self analyzeFile];
}

- (void)analyzeFile
{
	if ([self.fileList count] > 0) {
		// Disable two button
		[m_singleChooseButton setEnabled:NO];
		[m_singleCleanButton setEnabled:NO];

		//	[m_singleProgress setNeedsDisplay:YES];1
		NSString* filePath = [[self.fileList objectAtIndex:0] path];
		if (!filePath || [filePath isEqualToString:@""]) {
			NSAlert *alert= [NSAlert alertWithMessageText:@"Sorry" defaultButton:@"O K" alternateButton:nil otherButton:nil
								informativeTextWithFormat:@"Select your rom please！"];
			if ([alert runModal] != NSAlertDefaultReturn) {
				//		NSLog(@"Clicked cancel");
			} else {
				//		NSLog(@"Clicked OK");
			}
			[m_singleChooseButton setEnabled:YES];
			[m_singleCleanButton setEnabled:YES];
			return;
		}
		// create other thread to optimization rom
//		m_myThread = [[NSThread alloc] initWithTarget:self
//											 selector:@selector(optimizationFile:)
//											   object:filePath];
//		[m_myThread start];
		[NSThread detachNewThreadSelector:@selector(optimizationFile:) toTarget:self withObject:filePath];
	}
}

/*
 * optimization ROM file(used new thread)
 */
- (void)optimizationFile:(NSString*)filePath
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:[NSString stringWithFormat:@"Start analyze ROM:\n%@", filePath]];
	FILE* fp = fopen([filePath UTF8String], "rb");
    if (!fp) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"Open ROM failed!"];
        return;
    }
	// Get file size，move cursor to tail and get tail cursor to head cursor size.
	fseek(fp, 0L, SEEK_END);
	long fileSize = ftell(fp);
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationSetFileSize" object:[NSString stringWithFormat:@"%ld", fileSize]];
	// 切块分析(block size 10M)
	long long dataLength = 0;
	int readCount = 0;
	long destinyBlockSize = BLOCKSIZE;
	BOOL isFind = NO;
	int tempChar;
	// so...the file pointer in tail.
	while (ftell(fp) > 0) {
		// Move file pointer with on block(when file size less than original block size, use file size)
		if (ftell(fp) >= BLOCKSIZE) {
			destinyBlockSize = BLOCKSIZE;
		} else {
			destinyBlockSize = ftell(fp);
		}
		fseek(fp, -destinyBlockSize, SEEK_CUR);
		readCount = 0;
		while((tempChar = getc(fp)) != EOF) {
			if (readCount >= destinyBlockSize) break;
			if (tempChar != 255) {
				isFind = YES;
				break;
			}
			++readCount;
		}
		if (isFind) {
			// start reverse check this block
			long long dataLen = dataLength;
			for(long long i = 1; i <= destinyBlockSize; i++) {
				fseek(fp, -dataLen - i, SEEK_END);
				if (getc(fp) != 255) {
					break;
				}
//					NSLog(@"char : %d", getc(fp));
				++dataLength;
				// post notification to main thread
				if (dataLength % 100000 == 0) {
					[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAnalyzeSize" object:[NSString stringWithFormat:@"%lld", dataLength]];
				}
			}
			break;
		} else {
			// Reset file pointer, because last find operation was moved file pointer.
			fseek(fp, -dataLength - destinyBlockSize, SEEK_END);
		}
		dataLength += destinyBlockSize;
		// post notification to main thread
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAnalyzeSize" object:[NSString stringWithFormat:@"%lld", dataLength]];
	}
	// If dataLength less than 1 then not necessary to optimize.
	if (dataLength < 1) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"ROM is not necessary to optimize!"];
		fclose(fp);
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAllDone" object:nil];
		[pool release];
		return;
	}
	// Computing finally file size.
	dataLength = fileSize - dataLength;
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationSetFileSize" object:[NSString stringWithFormat:@"%lld", dataLength]];
	// Move file pointer to 0
	rewind(fp);
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"Analyze success, start write to new file!"];
	// writing to temp file
	NSString* newFilePath = [NSString stringWithFormat:@"%@.temp", filePath];
	FILE* newFp = fopen([newFilePath UTF8String], "wb");
	if (!newFp) {
#ifdef DEBUG
		NSLog(@"Open target file:%@ failed.", newFilePath);
#endif
        return;
    }
	int ch = 0;
	long long newDataLength = 0;
	while((ch = getc(fp)) != EOF) {
		if (newDataLength >= dataLength) break;
		fputc(ch, newFp);
		++newDataLength;
		if (newDataLength % 100000 == 0) {
			[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationWriteSize" object:[NSString stringWithFormat:@"%lld", newDataLength]];
		}
	}
	fclose(newFp);
	fclose(fp);
	// Remove and rename operations must be after close the file pointer.
	int removeStatus = remove([filePath UTF8String]);
	if (removeStatus != 0) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"Remove old rom failed！"];
	}
#ifdef DEBUG
	else {
		NSLog(@"Remove old rom success!");
	}
#endif
	int renameStatus = rename([newFilePath UTF8String], [filePath UTF8String]);
	if (renameStatus != 0) {
		[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"Rename new rom failed!"];
	}
#ifdef DEBUG
	else {
		NSLog(@"Rename new rom success!");
	}
#endif
	
	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"Write success!"];

	[[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"kNotificationAllDone" object:nil];
	[pool release];
}

- (void)setFileSize:(NSNotification*)notification
{
	NSString* sizeString = (NSString*)[notification object];
	m_fileSize = [sizeString longLongValue];
}

- (void)analyzeSize:(NSNotification*)notification
{
	NSString* sizeString = (NSString*)[notification object];
	long long newSize = [sizeString longLongValue];
//	NSLog(@"value:%lld", newSize);
	[m_singleProgress setMaxValue:m_fileSize];
	[m_singleProgress setDoubleValue:m_fileSize - newSize];
	
	[m_singleBarText setStringValue:[NSString stringWithFormat:@"Analyze %0.3f%% = %0.1fMB", ((float)newSize / m_fileSize * 100.0f), (float)newSize / 1000000.0f]];
}

- (void)setWriteSize:(NSNotification*)notification
{
	NSString* sizeString = (NSString*)[notification object];
	long long newSize = [sizeString longLongValue];
	[m_singleProgress setMaxValue:m_fileSize];
	[m_singleProgress setDoubleValue:newSize];
	
	[m_singleBarText setStringValue:[NSString stringWithFormat:@"Writeing %0.1f MB", (float)newSize / 1000000.0f]];
}

- (void)allDone:(NSNotification*)notification
{
	[m_singleProgress setMaxValue:m_fileSize];
	[m_singleProgress setDoubleValue:0];
	[m_singleProgress stopAnimation:nil];
	[m_singleChooseButton setEnabled:YES];
	[m_singleCleanButton setEnabled:YES];
	[self.fileList removeObjectAtIndex:0];
	if ([self.fileList count] > 0) {
		[self analyzeFile];
	} else {
		[m_singleBarText setStringValue:@"All done!!!"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"kNotificationAddLog" object:@"All done!"];
		[m_singleFileText setStringValue:@""];
		// show alert when all Done
		NSAlert *alert = [NSAlert alertWithMessageText:@"Success" defaultButton:@"O K" alternateButton:nil otherButton:nil
							informativeTextWithFormat:@"All operation did success！"];
		if ([alert runModal] != NSAlertDefaultReturn) {
			//		NSLog(@"Clicked cancel button");
		} else {
			//		NSLog(@"Clicked OK button");
		}
	}
}

- (void)setLog:(NSNotification*)notification
{
	NSString* str = (NSString*)[notification object];
	[self addLogString:str];
}

#pragma mark - log operation function

- (void)addLogString:(NSString*)str
{
	if (m_logBox) {
		NSString* oldStr = [m_logBox string];
		NSString* newStr = NULL;
		if ([oldStr isEqualToString:@""]) {
			newStr = str;
		} else {
			newStr = [NSString stringWithFormat:@"%@\n%@", oldStr, str];
		}
		
		[m_logBox setString:newStr];
	}
}

- (void)cleanLog
{
	if (m_logBox) {
		[m_logBox setString:@""];
	}
}

#pragma mark -

- (void)dealloc
{
	// Remove all notification
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationSetFileSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAnalyzeSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationWriteSize" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAllDone" object:nil];
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self name:@"kNotificationAddLog" object:nil];
	// release operation
	self.fileList = nil;
	[super dealloc];
}

@end
