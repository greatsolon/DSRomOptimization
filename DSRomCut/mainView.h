//
//  mainView.h
//  DSRomCut
//
//  Created by orix on 10/29/13.
//  Copyright (c) 2013 orix. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface mainView : NSView
{
	NSButton*					m_singleChooseButton;
	NSButton*					m_singleCleanButton;
	
	NSTextField*				m_singleFileText;
	NSTextField*				m_singleLabel;
	
	NSProgressIndicator*		m_singleProgress;
	NSTextField*				m_singleBarText;
	
	NSTextView*					m_logBox;
	
	long long					m_fileSize;
	
	NSMutableArray*				m_fileList;
}

@property (nonatomic, assign) IBOutlet NSButton* singleChooseButton;
@property (nonatomic, assign) IBOutlet NSButton* singleCleanButton;
@property (nonatomic, assign) IBOutlet NSTextField* singleFileText;
@property (nonatomic, assign) IBOutlet NSTextField* singleLabel;
@property (nonatomic, assign) IBOutlet NSProgressIndicator* singleProgress;
@property (nonatomic, assign) IBOutlet NSTextField* singleBarText;
@property (nonatomic, assign) IBOutlet NSTextView* logBox;

@property (nonatomic, retain) NSMutableArray* fileList;

- (IBAction)chooseFiles:(id)sender;
- (IBAction)optimizationFiles:(id)sender;

- (void)analyzeFile;
- (void)setFileSize:(NSNotification*)notification;
- (void)analyzeSize:(NSNotification*)notification;
- (void)setWriteSize:(NSNotification*)notification;
- (void)allDone:(NSNotification*)notification;
- (void)setLog:(NSNotification*)notification;

- (void)optimizationFile:(NSString*)filePath;

- (void)addLogString:(NSString*)string;
- (void)cleanLog;

@end
